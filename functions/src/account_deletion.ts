import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const storage = admin.storage();

const callableRuntimeOptions = {
  region: "europe-west1",
  memory: "256MiB" as const,
  timeoutSeconds: 30, // Increased timeout for cleanups
  maxInstances: 10,
};

/**
 * Callable Cloud Function: requestAccountDeletion
 * Executes server-side, idempotent account cleanup and deletes user authentication account.
 */
export const requestAccountDeletion = onCall(callableRuntimeOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bu işlemi gerçekleştirmek için giriş yapmış olmalısınız.");
  }

  const uid = request.auth.uid;
  logger.info(`Emanetly Deletion: Initiating deletion process for user: ${uid}`);

  // 1. Check for active (non-terminal) transactions
  const activeStatuses = ["onlyInquiry", "pendingDiscussion", "accepted", "borrowed"];
  
  const [ownerRequests, requesterRequests] = await Promise.all([
    db.collection("borrowRequests").where("ownerId", "==", uid).get(),
    db.collection("borrowRequests").where("requesterId", "==", uid).get(),
  ]);

  const activeOwner = ownerRequests.docs.some((doc) => activeStatuses.includes(doc.data().status));
  const activeRequester = requesterRequests.docs.some((doc) => activeStatuses.includes(doc.data().status));

  if (activeOwner || activeRequester) {
    logger.warn(`Emanetly Deletion: Blocked deletion for ${uid} due to active borrow requests.`);
    throw new HttpsError(
      "failed-precondition",
      "Devam eden aktif bir emanet süreciniz bulunmaktadır. Lütfen bu süreci tamamlayın veya iptal edin."
    );
  }

  // 2. Track or fetch job status
  const jobRef = db.collection("accountDeletionJobs").doc(uid);
  let jobSnap = await jobRef.get();
  
  if (!jobSnap.exists) {
    await jobRef.set({
      uid: uid,
      status: "requested",
      stage_storage_deleted: false,
      stage_items_cleaned: false,
      stage_requests_anonymized: false,
      stage_messages_anonymized: false,
      stage_blocked_cleaned: false,
      stage_profile_deleted: false,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    jobSnap = await jobRef.get();
  }

  const job = jobSnap.data() || {};

  // Step 1: Storage Deletion
  if (!job.stage_storage_deleted) {
    try {
      logger.info(`Emanetly Deletion [${uid}]: Deleting storage assets...`);
      const bucket = storage.bucket();

      // Delete avatar
      const avatarFolder = `avatars/${uid}`;
      await bucket.deleteFiles({ prefix: avatarFolder }).catch(() => {});

      // Delete item folders owned by user
      const itemsQuery = await db.collection("items").where("lenderId", "==", uid).get();
      for (const itemDoc of itemsQuery.docs) {
        const itemId = itemDoc.id;
        const itemFolder = `items/${itemId}`;
        await bucket.deleteFiles({ prefix: itemFolder }).catch(() => {});
      }

      await jobRef.update({
        stage_storage_deleted: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`Emanetly Deletion [${uid}]: Error deleting storage files`, err);
      await jobRef.update({ status: "failed", error: "storage_delete_failed" });
      throw new HttpsError("internal", "Dosyalar temizlenirken bir hata oluştu.");
    }
  }

  // Step 2: Items Cleanup (Delete unrequested, anonymize requested)
  if (!job.stage_items_cleaned) {
    try {
      logger.info(`Emanetly Deletion [${uid}]: Cleaning items...`);
      const itemsQuery = await db.collection("items").where("lenderId", "==", uid).get();

      const batch = db.batch();
      for (const itemDoc of itemsQuery.docs) {
        const itemId = itemDoc.id;
        
        // Check if there are any requests associated with this item
        const requestsQuery = await db.collection("borrowRequests").where("itemId", "==", itemId).limit(1).get();
        
        if (requestsQuery.empty) {
          // Never requested: completely delete
          batch.delete(itemDoc.ref);
        } else {
          // Requested: anonymize and archive to keep history intact for requester
          batch.update(itemDoc.ref, {
            lenderId: null,
            lenderName: "Eski Kullanıcı",
            imageUrl: null,
            images: [],
            status: "archived",
            deletedOwner: true,
          });
        }
      }
      await batch.commit();

      await jobRef.update({
        stage_items_cleaned: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`Emanetly Deletion [${uid}]: Error cleaning items`, err);
      await jobRef.update({ status: "failed", error: "items_cleanup_failed" });
      throw new HttpsError("internal", "İlanlar temizlenirken bir hata oluştu.");
    }
  }

  // Step 3: Anonymize Requests (borrowRequests)
  if (!job.stage_requests_anonymized) {
    try {
      logger.info(`Emanetly Deletion [${uid}]: Anonymizing borrow requests...`);
      const batch = db.batch();

      // Clear owner fields
      for (const doc of ownerRequests.docs) {
        batch.update(doc.ref, {
          ownerId: null,
          lenderId: null,
          lenderName: "Eski Kullanıcı",
        });
      }

      // Clear requester fields
      for (const doc of requesterRequests.docs) {
        batch.update(doc.ref, {
          requesterId: null,
          borrowerId: null,
          borrowerName: "Eski Kullanıcı",
        });
      }

      await batch.commit();

      await jobRef.update({
        stage_requests_anonymized: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`Emanetly Deletion [${uid}]: Error anonymizing requests`, err);
      await jobRef.update({ status: "failed", error: "requests_anonymize_failed" });
      throw new HttpsError("internal", "Geçmiş talepler anonimleştirilirken bir hata oluştu.");
    }
  }

  // Step 4: Anonymize Chat Messages (chatMessages)
  if (!job.stage_messages_anonymized) {
    try {
      logger.info(`Emanetly Deletion [${uid}]: Anonymizing chat messages...`);
      const messagesQuery = await db.collection("chatMessages").where("senderId", "==", uid).get();
      
      const batch = db.batch();
      for (const msgDoc of messagesQuery.docs) {
        batch.update(msgDoc.ref, {
          senderId: null,
          senderName: "Eski Kullanıcı",
        });
      }
      await batch.commit();

      await jobRef.update({
        stage_messages_anonymized: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`Emanetly Deletion [${uid}]: Error anonymizing messages`, err);
      await jobRef.update({ status: "failed", error: "messages_anonymize_failed" });
      throw new HttpsError("internal", "Mesaj geçmişi temizlenirken bir hata oluştu.");
    }
  }

  // Step 5: Clean Blocks, userRelations, and Favorites, and Delete Username Claim
  if (!job.stage_blocked_cleaned) {
    try {
      logger.info(`Emanetly Deletion [${uid}]: Cleaning blocked lists & relations and username claim...`);
      const batch = db.batch();

      // Read profile doc to get usernameNormalized
      const profileSnap = await db.collection("users").doc(uid).get();
      if (profileSnap.exists) {
        const profileData = profileSnap.data() || {};
        const usernameNormalized = profileData.usernameNormalized;
        if (usernameNormalized) {
          const claimRef = db.collection("usernames").doc(usernameNormalized);
          const claimSnap = await claimRef.get();
          if (claimSnap.exists) {
            const claimData = claimSnap.data() || {};
            // Verify claim ownership before deletion
            if (claimData.uid === uid) {
              batch.delete(claimRef);
              logger.info(`Emanetly Deletion [${uid}]: Queued username claim deletion for: ${usernameNormalized}`);
            } else {
              logger.warn(`Emanetly Deletion [${uid}]: Claim owner mismatch for username: ${usernameNormalized}, not deleting.`);
            }
          }
        }
      }

      // Delete userRelations containing this user
      const relationsQuery = await db.collection("userRelations").where("users", "array-contains", uid).get();
      for (const relDoc of relationsQuery.docs) {
        batch.delete(relDoc.ref);
      }

      // Delete other users' block targeting this user (collectionGroup query)
      try {
        const groupBlockQuery = await db.collectionGroup("blockedUsers").where("blockedUserId", "==", uid).get();
        for (const blockDoc of groupBlockQuery.docs) {
          batch.delete(blockDoc.ref);
        }
      } catch (e) {
        logger.warn(`Emanetly Deletion [${uid}]: Non-critical error query collectionGroup blockedUsers (index might be missing/building):`, e);
      }

      // Delete my blockedUsers subcollection
      const myBlockedQuery = await db.collection("users").doc(uid).collection("blockedUsers").get();
      for (const blockDoc of myBlockedQuery.docs) {
        batch.delete(blockDoc.ref);
      }

      await batch.commit();

      await jobRef.update({
        stage_blocked_cleaned: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`Emanetly Deletion [${uid}]: Error cleaning blocks and relations`, err);
      await jobRef.update({ status: "failed", error: "blocked_clean_failed" });
      throw new HttpsError("internal", "İlişkiler temizlenirken bir hata oluştu.");
    }
  }

  // Step 6: Delete Profile and Subcollections (Notifications)
  if (!job.stage_profile_deleted) {
    try {
      logger.info(`Emanetly Deletion [${uid}]: Deleting profile doc and subcollections...`);
      const batch = db.batch();

      // Delete notifications subcollection
      const notifsQuery = await db.collection("users").doc(uid).collection("notifications").get();
      for (const notifDoc of notifsQuery.docs) {
        batch.delete(notifDoc.ref);
      }

      // Delete profile document
      const profileRef = db.collection("users").doc(uid);
      batch.delete(profileRef);

      await batch.commit();

      await jobRef.update({
        stage_profile_deleted: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error(`Emanetly Deletion [${uid}]: Error deleting profile document`, err);
      await jobRef.update({ status: "failed", error: "profile_delete_failed" });
      throw new HttpsError("internal", "Profil silinirken bir hata oluştu.");
    }
  }

  // Step 7: Delete Firebase Auth Account (Admin SDK)
  try {
    logger.info(`Emanetly Deletion [${uid}]: Deleting Firebase Auth user...`);
    await admin.auth().deleteUser(uid);

    // Finalize deletion job with a 7-day retention TTL
    await jobRef.update({
      status: "completed",
      expireAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days retention
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    logger.info(`Emanetly Deletion [${uid}]: Process completed successfully.`);
    return { success: true };
  } catch (err) {
    logger.error(`Emanetly Deletion [${uid}]: Error deleting Auth User`, err);
    await jobRef.update({ status: "failed", error: "auth_user_delete_failed" });
    throw new HttpsError("internal", "Auth hesabı silinirken bir hata oluştu.");
  }
});
