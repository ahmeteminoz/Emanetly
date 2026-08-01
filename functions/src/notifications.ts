import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

// Initialize Admin SDK once if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Normalizes event.id into a safe SHA-256 hash for document ID
 */
function getEventDocId(eventId: string): string {
  return crypto.createHash("sha256").update(eventId).digest("hex");
}

/**
 * Idempotent execution wrapper using notificationEvents collection with 7-day TTL
 */
export async function runIdempotent(eventId: string, task: () => Promise<void>): Promise<void> {
  const docId = getEventDocId(eventId);
  const eventRef = db.collection("notificationEvents").doc(docId);

  // 1. Transaction to check and set 'processing'
  const shouldProceed = await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(eventRef);
    if (doc.exists) {
      const data = doc.data();
      if (data && (data.status === "processing" || data.status === "completed")) {
        logger.info(`Emanetly FCM: Event ${eventId} (doc: ${docId}) already in state '${data.status}'. Skipping.`);
        return false;
      }
    }
    
    // Set TTL expiration date to 7 days from now
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    // Set to processing
    transaction.set(eventRef, {
      status: "processing",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: expiresAt, // Firestore TTL automatically prunes this after 7 days
    });
    return true;
  });

  if (!shouldProceed) return;

  // 2. Execute task and update event status
  try {
    await task();
    await eventRef.update({
      status: "completed",
      completedAt: FieldValue.serverTimestamp(),
    });
  } catch (error: any) {
    logger.error(`Emanetly FCM: Task execution failed for event ${eventId}:`, error);
    await eventRef.update({
      status: "failed",
      error: error?.message || "Unknown error",
      failedAt: FieldValue.serverTimestamp(),
    });
    throw error;
  }
}

/**
 * Record technical suppression outcome on notification event doc (Observability)
 */
export async function markSuppressed(eventId: string, reason: string): Promise<void> {
  const docId = getEventDocId(eventId);
  const eventRef = db.collection("notificationEvents").doc(docId);
  try {
    await eventRef.update({
      status: "completed",
      outcome: "suppressed",
      reason: reason,
      completedAt: FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Ignore update failures on event doc
  }
}

/**
 * Creates an in-app notification document under users/{userId}/notifications/{eventId}.
 * Uses create-if-absent semantics to prevent overwriting existing documents or resetting readAt on retries.
 */
export async function createInAppNotification(
  userId: string,
  eventId: string,
  data: {
    type: string;
    title: string;
    body: string;
    requestId?: string;
    itemId?: string;
    senderId?: string;
  }
): Promise<void> {
  const notifRef = db.collection("users").doc(userId).collection("notifications").doc(eventId);
  try {
    await notifRef.create({
      type: data.type,
      title: data.title,
      body: data.body,
      requestId: data.requestId || null,
      itemId: data.itemId || null,
      senderId: data.senderId || null,
      readAt: null,
      dismissedAt: null,
      schemaVersion: 1,
      createdAt: FieldValue.serverTimestamp(),
    });
    logger.info(`Emanetly Notification: Created in-app notification for user ${userId} (docId: ${eventId}).`);
  } catch (error: any) {
    // If code 6 (ALREADY_EXISTS), ignore gracefully to preserve existing document and readAt timestamp
    if (error?.code === 6 || error?.code === "already-exists" || error?.message?.includes("ALREADY_EXISTS")) {
      logger.info(`Emanetly Notification: Notification doc ${eventId} already exists for user ${userId}. Preserving existing record.`);
    } else {
      logger.error(`Emanetly Notification: Error creating in-app notification for user ${userId}:`, error);
    }
  }
}

/**
 * Resolves FCM tokens for a user, sends multicast push, and prunes invalid tokens atomically
 */
export async function sendPushNotification(
  userId: string,
  payload: { title: string; body: string; data: Record<string, string> }
): Promise<void> {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    logger.warn(`Emanetly FCM: User ${userId} not found in Firestore. Skipping notification.`);
    return;
  }

  const userData = userDoc.data();
  const tokens: string[] = userData?.fcmTokens || [];

  if (tokens.length === 0) {
    logger.info(`Emanetly FCM: User ${userId} has no registered FCM tokens. Skipping.`);
    return;
  }

  const message: admin.messaging.MulticastMessage = {
    tokens: tokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: payload.data,
    android: {
      notification: {
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  logger.info(`Emanetly FCM: Multicast sent to ${tokens.length} tokens. Success count: ${response.successCount}`);

  // Handle invalid/expired tokens pruning
  const tokensToRemove: string[] = [];
  response.responses.forEach((res, index) => {
    if (!res.success && res.error) {
      const code = res.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        tokensToRemove.push(tokens[index]);
      }
    }
  });

  if (tokensToRemove.length > 0) {
    logger.info(`Emanetly FCM: Pruning ${tokensToRemove.length} invalid tokens for user ${userId}.`);
    await userRef.update({
      fcmTokens: FieldValue.arrayRemove(...tokensToRemove),
    });
  }
}
