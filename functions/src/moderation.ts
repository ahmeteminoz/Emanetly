import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const callableRuntimeOptions = {
  region: "europe-west1",
  memory: "256MiB" as const,
  timeoutSeconds: 15,
  maxInstances: 10,
};

/**
 * Checks bidirectional block status between userA and userB using Admin SDK.
 * Returns true if userA blocked userB OR userB blocked userA.
 */
export async function checkMutualBlock(userA: string, userB: string): Promise<boolean> {
  if (!userA || !userB || userA === userB) return false;

  try {
    const [blockA, blockB] = await Promise.all([
      db.collection("users").doc(userA).collection("blockedUsers").doc(userB).get(),
      db.collection("users").doc(userB).collection("blockedUsers").doc(userA).get(),
    ]);

    const isBlocked = blockA.exists || blockB.exists;
    if (isBlocked) {
      logger.info("Emanetly Moderation: Mutual block check triggered (suppression active).");
    }
    return isBlocked;
  } catch (error) {
    logger.error("Emanetly Moderation: Fail-closed error in checkMutualBlock:", error);
    // Rethrow error to trigger Cloud Function retry rather than leaking notifications (fail-closed strategy)
    throw error;
  }
}

const ALLOWED_REASONS: Record<string, string[]> = {
  listing: ["spam", "inappropriate_content", "misleading_location", "other"],
  user: ["harassment", "spam", "fake_account", "other"],
  message: ["abusive_language", "spam", "harassment", "other"],
};

/**
 * Callable Cloud Function: createReport
 * Generates a report with deterministic deduplication and server-side target resolution.
 */
export const createReport = onCall(callableRuntimeOptions, async (request) => {
  // 1. Authenticated user check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Rapor oluşturmak için giriş yapmış olmalısınız.");
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "E-posta adresi doğrulanmamış kullanıcılar rapor oluşturamaz.");
  }

  const reporterId = request.auth.uid;
  const data = request.data || {};
  const { targetType, targetId, reason, details } = data;

  // 2. Input validation
  if (!targetType || !["listing", "user", "message"].includes(targetType)) {
    throw new HttpsError("invalid-argument", "Geçersiz hedef tipi (targetType).");
  }

  if (!targetId || typeof targetId !== "string" || targetId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Geçersiz hedef ID (targetId).");
  }

  const allowedForType = ALLOWED_REASONS[targetType] || [];
  if (!reason || !allowedForType.includes(reason)) {
    throw new HttpsError("invalid-argument", `Geçersiz rapor nedeni (${reason}) bu hedef tipi için kabul edilmiyor.`);
  }

  const trimmedDetails = typeof details === "string" ? details.trim() : "";
  if (trimmedDetails.length > 500) {
    throw new HttpsError("invalid-argument", "Açıklama metni 500 karakterden uzun olamaz.");
  }

  // 3. Server-side target resolution & authorization
  let targetUserId = "";
  let requestId: string | null = null;

  if (targetType === "listing") {
    const itemDoc = await db.collection("items").doc(targetId).get();
    if (!itemDoc.exists) {
      throw new HttpsError("not-found", "Raporlanmak istenen ilan bulunamadı.");
    }
    const itemData = itemDoc.data();
    targetUserId = itemData?.lenderId || itemData?.ownerId || "";
  } else if (targetType === "user") {
    const userDoc = await db.collection("users").doc(targetId).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Raporlanmak istenen kullanıcı bulunamadı.");
    }
    targetUserId = targetId;
  } else if (targetType === "message") {
    const msgDoc = await db.collection("chatMessages").doc(targetId).get();
    if (!msgDoc.exists) {
      throw new HttpsError("not-found", "Raporlanmak istenen mesaj bulunamadı.");
    }
    const msgData = msgDoc.data();
    targetUserId = msgData?.senderId || "";
    requestId = msgData?.requestId || null;

    // Verify caller is a participant in the request
    if (requestId) {
      const reqDoc = await db.collection("borrowRequests").doc(requestId).get();
      if (!reqDoc.exists) {
        throw new HttpsError("permission-denied", "İlgili talep bulunamadı.");
      }
      const reqData = reqDoc.data();
      const isParticipant =
        reqData &&
        (reqData.ownerId === reporterId ||
          reqData.lenderId === reporterId ||
          reqData.requesterId === reporterId ||
          reqData.borrowerId === reporterId);
      if (!isParticipant) {
        throw new HttpsError("permission-denied", "Tarafı olmadığınız bir mesajı raporlayamazsınız.");
      }
    }
  }

  // 4. Prevent self-reporting
  if (reporterId === targetUserId) {
    throw new HttpsError("failed-precondition", "Kullanıcı kendisini veya kendi içeriğini raporlayamaz.");
  }

  // 5. Deterministic deduplication ID
  const dedupRaw = `${reporterId}_${targetType}_${targetId}`;
  const reportDocId = crypto.createHash("sha256").update(dedupRaw).digest("hex");
  const reportRef = db.collection("reports").doc(reportDocId);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(reportRef);
    if (doc.exists) {
      const existingData = doc.data();
      const lastTime = existingData?.lastSubmittedAt?.toDate?.() || existingData?.firstSubmittedAt?.toDate?.();

      // 60-second cooldown rate-limiting per reporter per target
      if (lastTime && Date.now() - lastTime.getTime() < 60000) {
        throw new HttpsError(
          "resource-exhausted",
          "Bu içeriği çok yakın zamanda raporladınız. Lütfen kısa bir süre bekleyin."
        );
      }

      const currentCount = existingData?.submissionCount || 1;

      // Re-open status to 'pending' if previously resolved/dismissed by moderator
      transaction.update(reportRef, {
        reason: reason,
        details: trimmedDetails,
        submissionCount: currentCount + 1,
        status: "pending",
        lastSubmittedAt: FieldValue.serverTimestamp(),
      });
      logger.info(`Emanetly Moderation: Re-submitted report ${reportDocId} (count: ${currentCount + 1}).`);
    } else {
      // Create brand new report
      transaction.set(reportRef, {
        reporterId: reporterId,
        targetType: targetType,
        targetId: targetId,
        targetUserId: targetUserId,
        requestId: requestId,
        reason: reason,
        details: trimmedDetails,
        status: "pending",
        submissionCount: 1,
        firstSubmittedAt: FieldValue.serverTimestamp(),
        lastSubmittedAt: FieldValue.serverTimestamp(),
      });
      logger.info(`Emanetly Moderation: Created new report ${reportDocId}.`);
    }
  });

  return { success: true, reportId: reportDocId };
});

/**
 * Callable Cloud Function: toggleBlockUser
 * Idempotently toggles block status and manages bidirectional userRelations document atomically.
 */
export const toggleBlockUser = onCall(callableRuntimeOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bu işlemi gerçekleştirmek için giriş yapmış olmalısınız.");
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "E-posta adresi doğrulanmamış kullanıcılar engelleme işlemi yapamaz.");
  }

  const callerUid = request.auth.uid;
  const data = request.data || {};
  const { targetUserId, shouldBlock, source } = data;

  if (!targetUserId || typeof targetUserId !== "string" || targetUserId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Geçersiz hedef kullanıcı (targetUserId).");
  }

  if (callerUid === targetUserId) {
    throw new HttpsError("failed-precondition", "Kullanıcı kendisini engelleyemez.");
  }

  if (typeof shouldBlock !== "boolean") {
    throw new HttpsError("invalid-argument", "shouldBlock boolean olmalıdır.");
  }

  // 1. Verify target user exists
  const targetUserDoc = await db.collection("users").doc(targetUserId).get();
  if (!targetUserDoc.exists) {
    throw new HttpsError("not-found", "Engellenmek istenen kullanıcı bulunamadı.");
  }

  // 2. Deterministic SHA-256 Relation ID calculation
  const sortedUids = [callerUid, targetUserId].sort();
  const rawId = `${sortedUids[0]}:${sortedUids[1]}`;
  const relationId = crypto.createHash("sha256").update(rawId).digest("hex");

  const callerBlockRef = db.collection("users").doc(callerUid).collection("blockedUsers").doc(targetUserId);
  const targetBlockRef = db.collection("users").doc(targetUserId).collection("blockedUsers").doc(callerUid);
  const relationRef = db.collection("userRelations").doc(relationId);

  await db.runTransaction(async (transaction) => {
    const [callerBlockSnap, targetBlockSnap] = await Promise.all([
      transaction.get(callerBlockRef),
      transaction.get(targetBlockRef),
    ]);

    if (shouldBlock) {
      // Create block doc if absent, preserving existing createdAt on idempotent calls
      if (!callerBlockSnap.exists) {
        transaction.set(callerBlockRef, {
          blockedUserId: targetUserId,
          createdAt: FieldValue.serverTimestamp(),
          source: typeof source === "string" ? source : "profile",
        });
      }

      // Upsert relation document (contains ONLY users, interactionBlocked, updatedAt)
      transaction.set(relationRef, {
        users: sortedUids,
        interactionBlocked: true,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      logger.info(`Emanetly Moderation: User ${callerUid} blocked ${targetUserId}. Relation ${relationId} updated.`);
    } else {
      // Unblock: delete caller's block doc if exists
      if (callerBlockSnap.exists) {
        transaction.delete(callerBlockRef);
      }

      // Check if target user STILL blocks caller (reverse block)
      if (targetBlockSnap.exists) {
        // Reverse block remains active, keep relation document true
        transaction.set(relationRef, {
          users: sortedUids,
          interactionBlocked: true,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        logger.info(`Emanetly Moderation: User ${callerUid} unblocked ${targetUserId}, but reverse block remains active.`);
      } else {
        // No blocks in either direction: delete relation document
        transaction.delete(relationRef);
        logger.info(`Emanetly Moderation: Bidirectional block cleared between ${callerUid} and ${targetUserId}. Relation ${relationId} deleted.`);
      }
    }
  });

  return { success: true, isBlocked: shouldBlock };
});
