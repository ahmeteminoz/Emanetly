import * as admin from "firebase-admin";
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

export const confirmHandoverAction = onCall(callableRuntimeOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const { requestId, action } = request.data;
  if (!requestId || typeof requestId !== "string") {
    throw new HttpsError("invalid-argument", "requestId must be a non-empty string");
  }

  const validActions = [
    "lender_handover",
    "borrower_receipt",
    "borrower_return",
    "lender_return_receipt",
  ];
  if (!action || !validActions.includes(action)) {
    throw new HttpsError(
      "invalid-argument",
      `action must be one of: ${validActions.join(", ")}`
    );
  }

  const callerUid = request.auth.uid;

  try {
    return await db.runTransaction(async (transaction) => {
      const reqRef = db.collection("borrowRequests").doc(requestId);
      const reqSnap = await transaction.get(reqRef);
      if (!reqSnap.exists) {
        throw new HttpsError("not-found", "Borrow request not found");
      }

      const reqData = reqSnap.data()!;
      
      // Idempotency: If request is already completed, return immediately
      if (reqData.status === "completed") {
        return {
          success: true,
          alreadyConfirmed: true,
          status: "completed",
        };
      }

      const isOwner = callerUid === reqData.ownerId;
      const isRequester = callerUid === reqData.requesterId;
      if (!isOwner && !isRequester) {
        throw new HttpsError("permission-denied", "You are not a participant in this request");
      }

      const itemId = reqData.itemId;
      const itemRef = db.collection("items").doc(itemId);
      const itemSnap = await transaction.get(itemRef);
      if (!itemSnap.exists) {
        throw new HttpsError("not-found", "Item not found");
      }

      const itemData = itemSnap.data()!;

      // Integrity Checks
      if (itemData.lenderId !== reqData.ownerId) {
        throw new HttpsError("failed-precondition", "Request owner does not match item lender");
      }

      // Action validation
      if (action === "lender_handover") {
        if (!isOwner) {
          throw new HttpsError("permission-denied", "Only the owner can confirm handover");
        }
        if (reqData.status !== "accepted") {
          throw new HttpsError("failed-precondition", "Request status must be accepted to confirm handover");
        }
        if (itemData.status !== "pendingApproval" && itemData.status !== "borrowed") {
          throw new HttpsError("failed-precondition", "Item must be pending approval or already borrowed");
        }
      } else if (action === "borrower_receipt") {
        if (!isRequester) {
          throw new HttpsError("permission-denied", "Only the borrower can confirm receipt");
        }
        if (reqData.status !== "accepted") {
          throw new HttpsError("failed-precondition", "Request status must be accepted to confirm receipt");
        }
        if (itemData.status !== "pendingApproval" && itemData.status !== "borrowed") {
          throw new HttpsError("failed-precondition", "Item must be pending approval or already borrowed");
        }
      } else if (action === "borrower_return") {
        if (!isRequester) {
          throw new HttpsError("permission-denied", "Only the borrower can confirm return");
        }
        if (reqData.status !== "borrowed") {
          throw new HttpsError("failed-precondition", "Request must be borrowed to confirm return");
        }
        if (itemData.status !== "borrowed" && itemData.status !== "pendingReturn") {
          throw new HttpsError("failed-precondition", "Item must be borrowed or pending return");
        }
      } else if (action === "lender_return_receipt") {
        if (!isOwner) {
          throw new HttpsError("permission-denied", "Only the owner can confirm return receipt");
        }
        if (reqData.status !== "borrowed") {
          throw new HttpsError("failed-precondition", "Request must be borrowed to confirm return receipt");
        }
        if (itemData.status !== "borrowed" && itemData.status !== "pendingReturn") {
          throw new HttpsError("failed-precondition", "Item must be borrowed or pending return");
        }
      }

      // Read existing confirmations
      const existingLenderHandover = reqData.handoverLenderConfirmedAt != null;
      const existingBorrowerReceipt = reqData.handoverBorrowerConfirmedAt != null;
      const existingBorrowerReturn = reqData.returnBorrowerConfirmedAt != null;
      const existingLenderReturnReceipt = reqData.returnLenderConfirmedAt != null;

      // Check if current action is duplicate
      if (
        (action === "lender_handover" && existingLenderHandover) ||
        (action === "borrower_receipt" && existingBorrowerReceipt) ||
        (action === "borrower_return" && existingBorrowerReturn) ||
        (action === "lender_return_receipt" && existingLenderReturnReceipt)
      ) {
        return {
          success: true,
          alreadyConfirmed: true,
          status: reqData.status,
        };
      }

      // Calculate state changes
      const lenderHandover = existingLenderHandover || (action === "lender_handover");
      const borrowerReceipt = existingBorrowerReceipt || (action === "borrower_receipt");
      const borrowerReturn = existingBorrowerReturn || (action === "borrower_return");
      const lenderReturnReceipt = existingLenderReturnReceipt || (action === "lender_return_receipt");

      const requestUpdate: any = {};
      
      if (action === "lender_handover") {
        requestUpdate.handoverLenderConfirmedAt = FieldValue.serverTimestamp();
      } else if (action === "borrower_receipt") {
        requestUpdate.handoverBorrowerConfirmedAt = FieldValue.serverTimestamp();
      } else if (action === "borrower_return") {
        requestUpdate.returnBorrowerConfirmedAt = FieldValue.serverTimestamp();
      } else if (action === "lender_return_receipt") {
        requestUpdate.returnLenderConfirmedAt = FieldValue.serverTimestamp();
      }

      let newStatus = reqData.status;

      // Transition to borrowed
      if (lenderHandover && borrowerReceipt) {
        newStatus = "borrowed";
        requestUpdate.status = "borrowed";
        transaction.update(itemRef, {
          status: "borrowed",
          borrowerId: reqData.requesterId,
          deliveryStatus: "delivered",
        });
      }

      // Transition to completed
      if (borrowerReturn && lenderReturnReceipt) {
        newStatus = "completed";
        requestUpdate.status = "completed";
        transaction.update(itemRef, {
          status: "archived",
          borrowerId: null,
          borrowerName: null,
          deliveryStatus: null,
          meetingPoint: null,
        });

        // Increment successful statistics
        const lenderUserRef = db.collection("users").doc(reqData.ownerId);
        const borrowerUserRef = db.collection("users").doc(reqData.requesterId);
        transaction.update(lenderUserRef, {
          successfulLends: FieldValue.increment(1),
        });
        transaction.update(borrowerUserRef, {
          successfulBorrows: FieldValue.increment(1),
        });
      }

      transaction.update(reqRef, requestUpdate);

      return {
        success: true,
        alreadyConfirmed: false,
        status: newStatus,
      };
    });
  } catch (error: any) {
    logger.error("Error in confirmHandoverAction:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message || "Internal server error");
  }
});
