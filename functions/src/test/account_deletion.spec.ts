import * as admin from "firebase-admin";
import * as assert from "assert";
import { requestAccountDeletion } from "../account_deletion";

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

describe("Cloud Functions - Account Deletion Suite (v0.9.2)", () => {
  let db: admin.firestore.Firestore;

  before(async () => {
    if (!admin.apps.length) {
      process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
      process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
      admin.initializeApp({ projectId: "demo-emanetly" });
    }
    db = admin.firestore();
  });

  afterEach(async () => {
    // Clean up collections
    const collections = ["users", "items", "borrowRequests", "chatMessages", "userRelations", "accountDeletionJobs"];
    for (const col of collections) {
      const snap = await db.collection(col).get();
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  const invokeDeletion = (uid?: string): Promise<any> => {
    const req: any = {};
    if (uid) {
      req.auth = { uid, token: {} };
    }
    return (requestAccountDeletion as any).run(req);
  };

  it("fails with unauthenticated when request.auth is missing", async () => {
    await assertFailsWithCode(invokeDeletion(), "unauthenticated");
  });

  it("fails with failed-precondition when user has active borrow requests", async () => {
    const uid = "test_user_active";
    
    // Create an active request where the user is the owner
    await db.collection("borrowRequests").doc("req_active").set({
      ownerId: uid,
      requesterId: "other_user",
      itemId: "item_active",
      status: "accepted", // Active status
    });

    await assertFailsWithCode(invokeDeletion(uid), "failed-precondition");
  });

  it("succeeds and anonymizes data correctly when user has only terminal request history", async () => {
    const uid = "test_user_anonymize";
    
    // Create Auth user so Auth deletion does not fail
    await admin.auth().createUser({ uid }).catch(() => {});

    // Create user profile
    await db.collection("users").doc(uid).set({
      name: "Ahmet Emin",
      username: "ahmet",
      email: "ahmet@test.com",
    });

    // Create notification
    await db.collection("users").doc(uid).collection("notifications").doc("notif_1").set({
      title: "Test notification",
    });

    // Create item with borrow requests (requested item -> must be archived, not deleted)
    await db.collection("items").doc("item_1").set({
      lenderId: uid,
      lenderName: "Ahmet Emin",
      status: "available",
      images: ["image1.jpg"],
    });

    // Create item without requests (unrequested item -> must be deleted)
    await db.collection("items").doc("item_never_requested").set({
      lenderId: uid,
      lenderName: "Ahmet Emin",
      status: "available",
    });

    // Create terminal borrow request linking to item_1
    await db.collection("borrowRequests").doc("req_terminal").set({
      ownerId: uid,
      lenderId: uid,
      lenderName: "Ahmet Emin",
      requesterId: "other_user",
      itemId: "item_1",
      status: "completed", // Terminal status
    });

    // Create chat message
    await db.collection("chatMessages").doc("msg_1").set({
      senderId: uid,
      senderName: "Ahmet Emin",
      text: "Selam",
      requestId: "req_terminal",
    });

    // Invoke deletion
    const result = await invokeDeletion(uid);
    assert.strictEqual(result.success, true);

    // Verify profile is deleted
    const profileSnap = await db.collection("users").doc(uid).get();
    assert.strictEqual(profileSnap.exists, false);

    // Verify notification is deleted
    const notifSnap = await db.collection("users").doc(uid).collection("notifications").doc("notif_1").get();
    assert.strictEqual(notifSnap.exists, false);

    // Verify unrequested item is deleted
    const neverRequestedSnap = await db.collection("items").doc("item_never_requested").get();
    assert.strictEqual(neverRequestedSnap.exists, false);

    // Verify requested item is anonymized and archived
    const requestedItemSnap = await db.collection("items").doc("item_1").get();
    assert.strictEqual(requestedItemSnap.exists, true);
    const itemData = requestedItemSnap.data();
    assert.strictEqual(itemData?.lenderId, null);
    assert.strictEqual(itemData?.lenderName, "Eski Kullanıcı");
    assert.deepStrictEqual(itemData?.images, []);
    assert.strictEqual(itemData?.status, "archived");
    assert.strictEqual(itemData?.deletedOwner, true);

    // Verify borrow request is anonymized
    const reqSnap = await db.collection("borrowRequests").doc("req_terminal").get();
    assert.strictEqual(reqSnap.exists, true);
    const reqData = reqSnap.data();
    assert.strictEqual(reqData?.lenderId, null);
    assert.strictEqual(reqData?.lenderName, "Eski Kullanıcı");

    // Verify chat message is anonymized
    const msgSnap = await db.collection("chatMessages").doc("msg_1").get();
    assert.strictEqual(msgSnap.exists, true);
    const msgData = msgSnap.data();
    assert.strictEqual(msgData?.senderId, null);
    assert.strictEqual(msgData?.senderName, "Eski Kullanıcı");

    // Verify Auth user is deleted
    try {
      await admin.auth().getUser(uid);
      throw new Error("Expected Auth user to be deleted, but it still exists.");
    } catch (e: any) {
      assert.strictEqual(e.code, "auth/user-not-found");
    }
  });
});
