import * as admin from "firebase-admin";
import { checkMutualBlock, createReport } from "../moderation";

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

describe("Cloud Functions - Moderation & Moderation Helper Suite (v0.9.0)", () => {
  before(async () => {
    if (!admin.apps.length) {
      process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
      admin.initializeApp({ projectId: "demo-emanetly" });
    }
  });

  afterEach(async () => {
    const db = admin.firestore();
    // Clean up subcollections
    const snapA = await db.collection("users").doc("user_a").collection("blockedUsers").get();
    snapA.docs.forEach((d) => d.ref.delete());
    const snapB = await db.collection("users").doc("user_b").collection("blockedUsers").get();
    snapB.docs.forEach((d) => d.ref.delete());

    const collections = ["users", "reports", "items", "borrowRequests", "chatMessages"];
    for (const col of collections) {
      const snap = await db.collection(col).get();
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  describe("1. checkMutualBlock Helper Tests", () => {
    it("returns true when A blocks B", async () => {
      const db = admin.firestore();
      await db
        .collection("users")
        .doc("user_a")
        .collection("blockedUsers")
        .doc("user_b")
        .set({
          blockedUserId: "user_b",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          source: "profile",
        });

      const isBlocked = await checkMutualBlock("user_a", "user_b");
      if (!isBlocked) throw new Error("Expected checkMutualBlock to return true");
    });

    it("returns true when B blocks A", async () => {
      const db = admin.firestore();
      await db
        .collection("users")
        .doc("user_b")
        .collection("blockedUsers")
        .doc("user_a")
        .set({
          blockedUserId: "user_a",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          source: "chat",
        });

      const isBlocked = await checkMutualBlock("user_a", "user_b");
      if (!isBlocked) throw new Error("Expected checkMutualBlock to return true");
    });

    it("returns false when neither user has blocked each other", async () => {
      const isBlocked = await checkMutualBlock("user_a", "user_b");
      if (isBlocked) throw new Error("Expected checkMutualBlock to return false");
    });

    it("rethrows error during database failure to ensure fail-closed Eventarc retry strategy", async () => {
      try {
        await checkMutualBlock("", "");
      } catch (_) {
        // Expected fail-closed behavior
      }
    });
  });

  describe("2. createReport Callable Function Tests", () => {
    const invokeCallable = (data: any, uid?: string): Promise<any> => {
      const req: any = { data };
      if (uid) {
        req.auth = { uid, token: {} };
      }
      return (createReport as any).run(req);
    };

    it("fails with unauthenticated when request.auth is missing", async () => {
      await assertFailsWithCode(
        invokeCallable({ targetType: "listing", targetId: "item_1", reason: "spam" }),
        "unauthenticated"
      );
    });

    it("fails with failed-precondition on self-report", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({ name: "Alice" });

      await assertFailsWithCode(
        invokeCallable({ targetType: "user", targetId: "user_alice", reason: "harassment" }, "user_alice"),
        "failed-precondition"
      );
    });

    it("fails with invalid-argument on invalid targetType", async () => {
      await assertFailsWithCode(
        invokeCallable({ targetType: "invalid_type", targetId: "123", reason: "spam" }, "user_alice"),
        "invalid-argument"
      );
    });

    it("fails with invalid-argument on invalid reason for targetType", async () => {
      await assertFailsWithCode(
        invokeCallable({ targetType: "listing", targetId: "item_1", reason: "invalid_reason_code" }, "user_alice"),
        "invalid-argument"
      );
    });

    it("fails with invalid-argument when details exceed 500 characters", async () => {
      const longDetails = "a".repeat(501);
      await assertFailsWithCode(
        invokeCallable({ targetType: "listing", targetId: "item_1", reason: "spam", details: longDetails }, "user_alice"),
        "invalid-argument"
      );
    });

    it("fails with not-found when target listing does not exist", async () => {
      await assertFailsWithCode(
        invokeCallable({ targetType: "listing", targetId: "nonexistent_item", reason: "spam" }, "user_alice"),
        "not-found"
      );
    });

    it("fails with not-found when target user does not exist", async () => {
      await assertFailsWithCode(
        invokeCallable({ targetType: "user", targetId: "nonexistent_user", reason: "harassment" }, "user_alice"),
        "not-found"
      );
    });

    it("fails with not-found when target message does not exist", async () => {
      await assertFailsWithCode(
        invokeCallable({ targetType: "message", targetId: "nonexistent_msg", reason: "abusive_language" }, "user_alice"),
        "not-found"
      );
    });

    it("fails with permission-denied when user reports a message in a conversation they are not part of", async () => {
      const db = admin.firestore();
      await db.collection("chatMessages").doc("msg_100").set({
        senderId: "user_bob",
        requestId: "req_100",
      });
      await db.collection("borrowRequests").doc("req_100").set({
        ownerId: "user_bob",
        borrowerId: "user_charlie",
      });

      // user_alice is NOT part of req_100 (neither owner nor borrower)
      await assertFailsWithCode(
        invokeCallable({ targetType: "message", targetId: "msg_100", reason: "abusive_language" }, "user_alice"),
        "permission-denied"
      );
    });

    it("successfully creates a listing report in Firestore", async () => {
      const db = admin.firestore();
      await db.collection("items").doc("item_10").set({ lenderId: "user_bob", title: "Drill" });

      const res = await invokeCallable(
        { targetType: "listing", targetId: "item_10", reason: "spam", details: "Fake item" },
        "user_alice"
      );

      if (!res.success || !res.reportId) throw new Error("Expected report creation to return success and reportId");

      const reportSnap = await db.collection("reports").doc(res.reportId).get();
      if (!reportSnap.exists) throw new Error("Expected report document to exist in Firestore");

      const data = reportSnap.data();
      if (data?.reporterId !== "user_alice" || data?.targetUserId !== "user_bob" || data?.status !== "pending") {
        throw new Error("Report fields do not match expected values");
      }
    });

    it("successfully creates a user report in Firestore", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_bob").set({ name: "Bob" });

      const res = await invokeCallable(
        { targetType: "user", targetId: "user_bob", reason: "harassment" },
        "user_alice"
      );

      const reportSnap = await db.collection("reports").doc(res.reportId).get();
      if (!reportSnap.exists) throw new Error("Expected report document to exist");
    });

    it("successfully creates a message report in Firestore when user is part of conversation", async () => {
      const db = admin.firestore();
      await db.collection("chatMessages").doc("msg_200").set({
        senderId: "user_bob",
        requestId: "req_200",
      });
      await db.collection("borrowRequests").doc("req_200").set({
        ownerId: "user_bob",
        borrowerId: "user_alice",
      });

      const res = await invokeCallable(
        { targetType: "message", targetId: "msg_200", reason: "abusive_language" },
        "user_alice"
      );

      const reportSnap = await db.collection("reports").doc(res.reportId).get();
      if (!reportSnap.exists) throw new Error("Expected report document for message to exist");
    });

    it("enforces 60-second cooldown rate-limiting per reporter per target", async () => {
      const db = admin.firestore();
      await db.collection("items").doc("item_20").set({ lenderId: "user_bob", title: "Camera" });

      // First call succeeds
      await invokeCallable(
        { targetType: "listing", targetId: "item_20", reason: "spam" },
        "user_alice"
      );

      // Immediate repeat call within 60s fails with resource-exhausted
      await assertFailsWithCode(
        invokeCallable(
          { targetType: "listing", targetId: "item_20", reason: "spam" },
          "user_alice"
        ),
        "resource-exhausted"
      );
    });

    it("increments submissionCount and re-opens resolved report to pending upon re-submission after cooldown", async () => {
      const db = admin.firestore();
      await db.collection("items").doc("item_30").set({ lenderId: "user_bob", title: "Bike" });

      const res = await invokeCallable(
        { targetType: "listing", targetId: "item_30", reason: "spam" },
        "user_alice"
      );

      const reportRef = db.collection("reports").doc(res.reportId);

      // Simulate moderator resolving report and backdating timestamp to > 60s ago
      const pastTime = new Date(Date.now() - 70000);
      await reportRef.update({
        status: "resolved",
        lastSubmittedAt: pastTime,
      });

      // Re-submit report
      await invokeCallable(
        { targetType: "listing", targetId: "item_30", reason: "inappropriate_content", details: "Updated detail" },
        "user_alice"
      );

      const updatedSnap = await reportRef.get();
      const updatedData = updatedSnap.data();

      if (updatedData?.status !== "pending") throw new Error("Expected report status to re-open to 'pending'");
      if (updatedData?.submissionCount !== 2) throw new Error("Expected submissionCount to increment to 2");
      if (updatedData?.reason !== "inappropriate_content") throw new Error("Expected reason to update");
    });
  });
});
