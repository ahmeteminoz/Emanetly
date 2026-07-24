import * as admin from "firebase-admin";
import * as crypto from "crypto";

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
 * Idempotent execution wrapper using notificationEvents collection
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
        console.log(`Emanetly FCM: Event ${eventId} (doc: ${docId}) already in state '${data.status}'. Skipping.`);
        return false;
      }
    }
    
    // Set to processing
    transaction.set(eventRef, {
      status: "processing",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });

  if (!shouldProceed) return;

  // 2. Execute task and update event status
  try {
    await task();
    await eventRef.update({
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error: any) {
    console.error(`Emanetly FCM: Task execution failed for event ${eventId}:`, error);
    await eventRef.update({
      status: "failed",
      error: error?.message || "Unknown error",
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw error;
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
    console.log(`Emanetly FCM: User ${userId} not found in Firestore. Skipping notification.`);
    return;
  }

  const userData = userDoc.data();
  const tokens: string[] = userData?.fcmTokens || [];

  if (tokens.length === 0) {
    console.log(`Emanetly FCM: User ${userId} has no registered FCM tokens. Skipping.`);
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
  console.log(`Emanetly FCM: Multicast sent to ${tokens.length} tokens. Success count: ${response.successCount}`);

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
    console.log(`Emanetly FCM: Pruning ${tokensToRemove.length} invalid tokens for user ${userId}.`);
    await userRef.update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
    });
  }
}
