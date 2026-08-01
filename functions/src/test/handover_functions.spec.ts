import * as admin from "firebase-admin";
import { confirmHandoverAction } from "../handover";

async function assertFailsWithCode(p: Promise<any>, expectedCode: string) {
  try {
    await p;
    throw new Error(`Expected promise to fail with ${expectedCode}, but it succeeded.`);
  } catch (err: any) {
    if (err.message && err.message.startsWith("Expected promise to fail")) {
      throw err;
    }
    if (err.code !== expectedCode) {
      throw new Error(`Expected error code '${expectedCode}', but got '${err.code}' (${err.message}).`);
    }
  }
}

describe("Cloud Functions - Double-Confirm Handover System Suite (v0.9.1)", () => {
  before(async () => {
    if (!admin.apps.length) {
      process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
      admin.initializeApp({ projectId: "demo-emanetly" });
    }
  });

  afterEach(async () => {
    const db = admin.firestore();
    const collections = ["users", "items", "borrowRequests"];
    for (const col of collections) {
      const snap = await db.collection(col).get();
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  const invokeHandover = (data: any, uid?: string): Promise<any> => {
    const req: any = { data };
    if (uid) {
      req.auth = { uid, token: {} };
    }
    return (confirmHandoverAction as any).run(req);
  };

  describe("confirmHandoverAction Callable Function Tests", () => {
    it("fails with unauthenticated when request.auth is missing", async () => {
      await assertFailsWithCode(
        invokeHandover({ requestId: "req_1", action: "lender_handover" }),
        "unauthenticated"
      );
    });

    it("fails with invalid-argument when action is invalid", async () => {
      await assertFailsWithCode(
        invokeHandover({ requestId: "req_1", action: "invalid_action" }, "user_lender"),
        "invalid-argument"
      );
    });

    it("fails with permission-denied when user is not a participant", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "accepted",
      });

      await assertFailsWithCode(
        invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_stranger"),
        "permission-denied"
      );
    });

    it("fails with not-found when request does not exist", async () => {
      await assertFailsWithCode(
        invokeHandover({ requestId: "nonexistent_req", action: "lender_handover" }, "user_lender"),
        "not-found"
      );
    });

    it("fails with failed-precondition on integrity check mismatch", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "accepted",
      });
      // item lenderId is different from request ownerId
      await db.collection("items").doc("item_1").set({
        lenderId: "user_other_lender",
        status: "pendingApproval",
      });

      await assertFailsWithCode(
        invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_lender"),
        "failed-precondition"
      );
    });

    it("fails with permission-denied when wrong role tries to confirm lender_handover", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "accepted",
      });
      await db.collection("items").doc("item_1").set({
        lenderId: "user_lender",
        status: "pendingApproval",
      });

      await assertFailsWithCode(
        invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_borrower"),
        "permission-denied"
      );
    });

    it("successfully sets lender_handover timestamp on first call and is idempotent on repeat call", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "accepted",
      });
      await db.collection("items").doc("item_1").set({
        lenderId: "user_lender",
        status: "pendingApproval",
      });

      // First confirmation call
      const res1 = await invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_lender");
      if (!res1.success || res1.alreadyConfirmed) {
        throw new Error("Expected successful confirmation");
      }

      const reqSnap = await db.collection("borrowRequests").doc("req_1").get();
      const reqData = reqSnap.data()!;
      if (!reqData.handoverLenderConfirmedAt) {
        throw new Error("Expected handoverLenderConfirmedAt to be set");
      }

      // Repeat duplicate confirmation call (idempotent no-op)
      const res2 = await invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_lender");
      if (!res2.success || !res2.alreadyConfirmed) {
        throw new Error("Expected idempotent success response");
      }
    });

    it("transitions request and item status to borrowed when both handover confirmations are complete", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "accepted",
      });
      await db.collection("items").doc("item_1").set({
        lenderId: "user_lender",
        status: "pendingApproval",
        deliveryStatus: "routingStarted",
      });

      // Lender confirms handover
      await invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_lender");

      // Borrower confirms receipt
      const res = await invokeHandover({ requestId: "req_1", action: "borrower_receipt" }, "user_borrower");
      if (!res.success || res.status !== "borrowed") {
        throw new Error(`Expected transition to 'borrowed', but got ${res.status}`);
      }

      const reqSnap = await db.collection("borrowRequests").doc("req_1").get();
      if (reqSnap.data()?.status !== "borrowed") {
        throw new Error("Request status should be updated to borrowed");
      }

      const itemSnap = await db.collection("items").doc("item_1").get();
      const itemData = itemSnap.data()!;
      if (itemData.status !== "borrowed" || itemData.borrowerId !== "user_borrower" || itemData.deliveryStatus !== "delivered") {
        throw new Error("Item status and details should be updated to borrowed/delivered");
      }
    });

    it("transitions request to completed and item to archived and increments statistics upon complete return confirmations", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "borrowed",
      });
      await db.collection("items").doc("item_1").set({
        lenderId: "user_lender",
        borrowerId: "user_borrower",
        status: "borrowed",
        deliveryStatus: "delivered",
      });
      await db.collection("users").doc("user_lender").set({ successfulLends: 0 });
      await db.collection("users").doc("user_borrower").set({ successfulBorrows: 0 });

      // Borrower confirms return
      await invokeHandover({ requestId: "req_1", action: "borrower_return" }, "user_borrower");

      // Lender confirms return receipt
      const res = await invokeHandover({ requestId: "req_1", action: "lender_return_receipt" }, "user_lender");
      if (!res.success || res.status !== "completed") {
        throw new Error(`Expected transition to 'completed', but got ${res.status}`);
      }

      // Check request status
      const reqSnap = await db.collection("borrowRequests").doc("req_1").get();
      if (reqSnap.data()?.status !== "completed") {
        throw new Error("Request status should be completed");
      }

      // Check item status
      const itemSnap = await db.collection("items").doc("item_1").get();
      const itemData = itemSnap.data()!;
      if (itemData.status !== "archived" || itemData.borrowerId !== null || itemData.deliveryStatus !== null) {
        throw new Error("Item status should be archived and borrower fields nullified");
      }

      // Check statistics increments
      const lenderSnap = await db.collection("users").doc("user_lender").get();
      if (lenderSnap.data()?.successfulLends !== 1) {
        throw new Error("Lender successfulLends should be incremented to 1");
      }

      const borrowerSnap = await db.collection("users").doc("user_borrower").get();
      if (borrowerSnap.data()?.successfulBorrows !== 1) {
        throw new Error("Borrower successfulBorrows should be incremented to 1");
      }

      // Test idempotency: Calling it again does not increment stats twice
      const resIdempotent = await invokeHandover({ requestId: "req_1", action: "lender_return_receipt" }, "user_lender");
      if (!resIdempotent.success || !resIdempotent.alreadyConfirmed) {
        throw new Error("Expected duplicate call to return alreadyConfirmed = true");
      }

      const lenderSnap2 = await db.collection("users").doc("user_lender").get();
      if (lenderSnap2.data()?.successfulLends !== 1) {
        throw new Error("Lender successfulLends should remain 1");
      }
    });

    it("allows handover/return confirmation even when users are mutually blocked", async () => {
      const db = admin.firestore();
      await db.collection("borrowRequests").doc("req_1").set({
        ownerId: "user_lender",
        requesterId: "user_borrower",
        itemId: "item_1",
        status: "accepted",
      });
      await db.collection("items").doc("item_1").set({
        lenderId: "user_lender",
        status: "pendingApproval",
      });

      // Simulate a block from lender to borrower
      await db.collection("users").doc("user_lender").collection("blockedUsers").doc("user_borrower").set({
        blockedUserId: "user_borrower",
      });

      // Lender confirms handover - should succeed despite block
      const res = await invokeHandover({ requestId: "req_1", action: "lender_handover" }, "user_lender");
      if (!res.success || !res.status) {
        throw new Error("Handover confirmation should succeed despite user block");
      }
    });
  });
});
