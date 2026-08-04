import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { runIdempotent, sendPushNotification, createInAppNotification, markSuppressed } from "./notifications";
import { checkMutualBlock, createReport, toggleBlockUser } from "./moderation";
import { confirmHandoverAction } from "./handover";
import { requestAccountDeletion } from "./account_deletion";
import { setUsername } from "./username_callable";

export { createReport, toggleBlockUser, confirmHandoverAction, requestAccountDeletion, setUsername };

// Ensure Admin SDK is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Trigger runtime options for event-driven Firestore triggers with Gen 2 Eventarc retries
export const triggerRuntimeOptions = {
  region: "europe-west1",
  memory: "256MiB" as const,
  timeoutSeconds: 15,
  maxInstances: 10,
  retry: true, // Explicitly enable Eventarc retries for fail-closed triggers
};

// Callable runtime options for Https onCall functions (NO retry)
export const callableRuntimeOptions = {
  region: "europe-west1",
  memory: "256MiB" as const,
  timeoutSeconds: 15,
  maxInstances: 10,
};

/**
 * Triggered when a new chat message is created.
 */
export const onMessageCreated = onDocumentCreated(
  {
    document: "chatMessages/{messageId}",
    ...triggerRuntimeOptions,
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

      // Skip initial inquiry messages to prevent duplicate notifications
      if (message.customPayload === "initial_inquiry" || message.customPayload === "initial_request") {
        logger.info("Emanetly FCM: Initial request/inquiry message, skipping notification to prevent duplicates.");
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

      // Check if this is the initial user message in the request conversation to prevent double notification
      const querySnap = await db.collection("chatMessages")
        .where("requestId", "==", requestId)
        .get();

      const userMessages = querySnap.docs.filter((doc) => doc.data().type !== "system");
      if (userMessages.length <= 1) {
        logger.info(`Emanetly FCM: First user message in conversation for request ${requestId}, skipping notification to prevent duplicate.`);
        await markSuppressed(eventId, "first_user_message");
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

      // Check mutual block status (Suppression)
      const isBlocked = await checkMutualBlock(senderId, recipientId);
      if (isBlocked) {
        logger.info("Emanetly FCM: Notification suppressed due to mutual block between users.");
        await markSuppressed(eventId, "mutual_block");
        return;
      }

      // Check notification preferences for newMessages
      const recipientDoc = await db.collection("users").doc(recipientId).get();
      const recipientData = recipientDoc.data();
      const preferences = recipientData?.notificationPreferences || {};
      const newMessagesEnabled = preferences.newMessages !== false;

      // 4. Create In-App Notification (Decoupled & Create-If-Absent)
      const textPreview = message.text
        ? (message.text.length > 100 ? message.text.substring(0, 100) + "..." : message.text)
        : "Yeni bir mesaj";
      const notifTitle = `${senderName} size mesaj gönderdi`;

      await createInAppNotification(recipientId, eventId, {
        type: "chat",
        title: notifTitle,
        body: textPreview,
        requestId: requestId,
        itemId: request.itemId,
        senderId: senderId,
      });

      // 5. Send FCM Push Notification (only if enabled)
      if (newMessagesEnabled) {
        await sendPushNotification(recipientId, {
          title: notifTitle,
          body: textPreview,
          data: {
            type: "chat",
            requestId: requestId,
          },
        });
      } else {
        logger.info(`Emanetly FCM: Suppressed message push notification because newMessages preference is disabled for user ${recipientId}.`);
      }
    });
  }
);

/**
 * Triggered when a borrow request's status changes.
 */
export const onRequestStatusChanged = onDocumentUpdated(
  {
    document: "borrowRequests/{requestId}",
    ...triggerRuntimeOptions,
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
        case "borrowed":
          recipients.push(ownerId, requesterId);
          statusText = `"${itemTitle}" teslimatı her iki tarafça onaylandı. Ödünç süreci başladı.`;
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

      // 4. Create In-App Notification and Send FCM Push for each recipient
      for (const recipientId of uniqueRecipients) {
        const notifDocId = `${eventId}_${recipientId}`;
        const senderId = recipientId === ownerId ? requesterId : ownerId;

        const isBlocked = await checkMutualBlock(senderId, recipientId);
        if (isBlocked) {
          logger.info("Emanetly FCM: Suppressing status change notification due to block.");
          continue;
        }

        await createInAppNotification(recipientId, notifDocId, {
          type: status,
          title: "Talebiniz Güncellendi",
          body: statusText,
          requestId: requestId,
          itemId: itemId,
          senderId: senderId,
        });

        await sendPushNotification(recipientId, {
          title: "Talebiniz Güncellendi",
          body: statusText,
          data: {
            type: status,
            requestId: requestId,
          },
        });
      }
    });
  }
);

/**
 * Triggered when a new borrow request is created.
 */
export const onRequestCreated = onDocumentCreated(
  {
    document: "borrowRequests/{requestId}",
    ...triggerRuntimeOptions,
  },
  async (event) => {
    const requestSnap = event.data;
    if (!requestSnap) return;
    const request = requestSnap.data();
    if (!request) return;

    const requestId = event.params.requestId;
    const idempotentId = `request_created_${requestId}`;

    await runIdempotent(idempotentId, async () => {
      const status = request.status;
      const itemId = request.itemId;
      const recipientUid = request.ownerId; // Owner of item receives notification
      const senderUid = request.requesterId; // Requester is the sender of activity

      if (!status || !itemId || !recipientUid || !senderUid) return;

      // 1. Fetch item title
      const db = admin.firestore();
      let itemTitle = "Eşya";
      try {
        const itemDoc = await db.collection("items").doc(itemId).get();
        if (itemDoc.exists) {
          itemTitle = itemDoc.data()?.title || "Eşya";
        }
      } catch (_) {}

      // 2. Fetch requester's display name
      let requesterName = "Bir BANÜ Üyesi";
      try {
        const requesterDoc = await db.collection("users").doc(senderUid).get();
        if (requesterDoc.exists) {
          requesterName = requesterDoc.data()?.name || "Bir BANÜ Üyesi";
        }
      } catch (_) {}

      // 3. Check block suppression between requester and owner
      const isBlocked = await checkMutualBlock(senderUid, recipientUid);
      if (isBlocked) {
        logger.info("Emanetly FCM: Suppressing new request notification due to block.");
        await markSuppressed(idempotentId, "mutual_block");
        return;
      }

      // Check notification preferences for newBorrowRequests
      const recipientDoc = await db.collection("users").doc(recipientUid).get();
      const recipientData = recipientDoc.data();
      const preferences = recipientData?.notificationPreferences || {};
      const newBorrowRequestsEnabled = preferences.newBorrowRequests !== false;

      logger.info(`Emanetly Trigger Log [${requestId}]: ownerId=${recipientUid}, requesterId=${senderUid}, status=${status}, newBorrowRequestsEnabled=${newBorrowRequestsEnabled}, fcmTokensCount=${recipientData?.fcmTokens?.length || 0}`);

      // 4. Resolve notification texts based on status
      let notifTitle = "";
      let statusText = "";
      let notifType = "";

      if (status === "onlyInquiry") {
        notifTitle = "İlanınız hakkında yeni soru";
        statusText = `${requesterName}, "${itemTitle}" ilanı hakkında soru sordu.`;
        notifType = "listing_question_received";
      } else if (status === "pendingDiscussion") {
        notifTitle = "Yeni ödünç talebi";
        statusText = `${requesterName}, "${itemTitle}" ilanını ödünç almak istiyor.`;
        notifType = "borrow_request_received";
      } else {
        notifTitle = "Yeni ödünç talebi";
        statusText = `"${itemTitle}" için yeni bir talep oluşturuldu.`;
        notifType = "borrow_request_received";
      }

      // 5. Create In-App Notification (always occurs)
      await createInAppNotification(recipientUid, `${idempotentId}_${recipientUid}`, {
        type: notifType,
        title: notifTitle,
        body: statusText,
        requestId: requestId,
        itemId: itemId,
        senderId: senderUid,
      });

      // 6. Send FCM Push Notification (if preference is enabled)
      if (newBorrowRequestsEnabled) {
        await sendPushNotification(recipientUid, {
          title: notifTitle,
          body: statusText,
          data: {
            type: notifType,
            requestId: requestId,
            itemId: itemId,
            route: "request_chat",
          },
        });
      } else {
        logger.info(`Emanetly FCM: Suppressed newBorrowRequests push notification because preferences are disabled for user ${recipientUid}.`);
      }
    });
  }
);

