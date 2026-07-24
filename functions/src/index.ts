import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { runIdempotent, sendPushNotification } from "./notifications";

// Ensure Admin SDK is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Global runtime options for cost and performance optimization (Senior Best Practices)
const runtimeOptions = {
  region: "europe-west3", // Deploy closer to Turkey to minimize network latency
  memory: "256MiB" as const, // Reduce memory footprint to decrease Firestore project billings
  timeoutSeconds: 15, // Low timeout for quick fire-and-forget functions
  maxInstances: 10, // Prevent uncontrolled auto-scaling costs
};

/**
 * Triggered when a new chat message is created.
 */
export const onMessageCreated = onDocumentCreated(
  {
    document: "chatMessages/{messageId}",
    ...runtimeOptions,
  },
  async (event) => {
    const messageSnap = event.data;
    if (!messageSnap) return;
    const message = messageSnap.data();
    if (!message) return;

    const eventId = event.id;

    await runIdempotent(eventId, async () => {
      // 1. Skip system messages
      if (message.type === "system") {
        logger.info("Emanetly FCM: System message, skipping notification.");
        return;
      }

      const requestId = message.requestId;
      const senderId = message.senderId;
      const senderName = message.senderName || "Bir kullanıcı";

      if (!requestId || !senderId) {
        logger.warn("Emanetly FCM: Missing critical message fields (requestId/senderId). Skipping.");
        return;
      }

      // 2. Fetch corresponding borrow request
      const db = admin.firestore();
      const requestDoc = await db.collection("borrowRequests").doc(requestId).get();
      if (!requestDoc.exists) {
        logger.warn(`Emanetly FCM: Borrow request ${requestId} not found. Skipping.`);
        return;
      }

      const request = requestDoc.data();
      if (!request) return;

      // 3. Resolve recipient (the non-sender party)
      let recipientId = "";
      if (request.ownerId === senderId) {
        recipientId = request.requesterId;
      } else if (request.requesterId === senderId) {
        recipientId = request.ownerId;
      }

      if (!recipientId || recipientId === senderId) {
        logger.info("Emanetly FCM: Recipient resolved as sender or not found. Skipping.");
        return;
      }

      // 4. Send notification
      const textPreview = message.text
        ? (message.text.length > 100 ? message.text.substring(0, 100) + "..." : message.text)
        : "Yeni bir mesaj";

      await sendPushNotification(recipientId, {
        title: `${senderName} size mesaj gönderdi`,
        body: textPreview,
        data: {
          type: "chat",
          requestId: requestId,
        },
      });
    });
  }
);

/**
 * Triggered when a borrow request's status changes.
 */
export const onRequestStatusChanged = onDocumentUpdated(
  {
    document: "borrowRequests/{requestId}",
    ...runtimeOptions,
  },
  async (event) => {
    const change = event.data;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;

    // Run only if status actually changed
    if (before.status === after.status) {
      return;
    }

    const eventId = event.id;
    const requestId = event.params.requestId;

    await runIdempotent(eventId, async () => {
      const status = after.status;
      const itemId = after.itemId;
      const ownerId = after.ownerId;
      const requesterId = after.requesterId;

      if (!status || !itemId) return;

      // 1. Fetch real item title
      const db = admin.firestore();
      let itemTitle = "Eşya";
      try {
        const itemDoc = await db.collection("items").doc(itemId).get();
        if (itemDoc.exists) {
          itemTitle = itemDoc.data()?.title || "Eşya";
        }
      } catch (_) {}

      // 2. Resolve recipients and message body
      const recipients: string[] = [];
      let statusText = "";

      switch (status) {
        case "pendingApproval":
          recipients.push(ownerId);
          statusText = `"${itemTitle}" için yeni bir ödünç alma talebiniz var.`;
          break;
        case "accepted":
          recipients.push(requesterId);
          statusText = `"${itemTitle}" talebiniz kabul edildi! Buluşma detaylarını görün.`;
          break;
        case "rejected":
          recipients.push(requesterId);
          statusText = `"${itemTitle}" talebiniz maalesef reddedildi.`;
          break;
        case "cancelled":
          recipients.push(ownerId, requesterId);
          statusText = `"${itemTitle}" ödünç alma talebi iptal edildi.`;
          break;
        case "completed":
          recipients.push(ownerId, requesterId);
          statusText = `"${itemTitle}" başarıyla teslim edildi. Süreç tamamlandı.`;
          break;
        default:
          logger.info(`Emanetly FCM: Status '${status}' is not monitored for push. Skipping.`);
          return;
      }

      // 3. Deduplicate recipients
      const uniqueRecipients = Array.from(new Set(recipients));

      // 4. Send multicast notifications
      for (const recipientId of uniqueRecipients) {
        await sendPushNotification(recipientId, {
          title: "Talebiniz Güncellendi",
          body: statusText,
          data: {
            type: "request_detail",
            requestId: requestId,
          },
        });
      }
    });
  }
);
