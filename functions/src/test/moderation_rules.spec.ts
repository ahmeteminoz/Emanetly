import * as fs from "fs";
import * as path from "path";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

async function assertSucceeds(p: Promise<any>) {
  await p;
}

async function assertFails(p: Promise<any>) {
  try {
    await p;
    throw new Error("Expected promise to fail, but it succeeded.");
  } catch (err: any) {
    if (err.message === "Expected promise to fail, but it succeeded.") {
      throw err;
    }
  }
}

describe("Firestore Security Rules - Moderation (v0.9.0)", () => {
  let testEnv: RulesTestEnvironment;

  before(async () => {
    const rulesPath = path.resolve(__dirname, "../../../firestore.rules");
    const rules = fs.readFileSync(rulesPath, "utf8");

    testEnv = await initializeTestEnvironment({
      projectId: "demo-emanetly",
      firestore: {
        rules: rules,
        host: "127.0.0.1",
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  afterEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  });

  it("1. Owner can create, read, and delete valid block record", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertSucceeds(
      docRef.set({
        blockedUserId: "user_bob",
        createdAt: new Date(),
        source: "profile",
      })
    );

    await assertSucceeds(docRef.get());
    await assertSucceeds(docRef.delete());
  });

  it("2. Other users cannot read or delete another user's block record", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertSucceeds(
      docRef.set({
        blockedUserId: "user_bob",
        createdAt: new Date(),
        source: "profile",
      })
    );

    const bobContext = testEnv.authenticatedContext("user_bob");
    const bobDocRef = bobContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertFails(bobDocRef.get());
    await assertFails(bobDocRef.delete());
  });

  it("3. Update operation is strictly denied on block records", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertSucceeds(
      docRef.set({
        blockedUserId: "user_bob",
        createdAt: new Date(),
        source: "profile",
      })
    );

    await assertFails(
      docRef.update({
        source: "chat",
      })
    );
  });

  it("4. Owner cannot self-block", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_alice");

    await assertFails(
      docRef.set({
        blockedUserId: "user_alice",
        createdAt: new Date(),
        source: "profile",
      })
    );
  });

  it("5. Creation fails with invalid source enum", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertFails(
      docRef.set({
        blockedUserId: "user_bob",
        createdAt: new Date(),
        source: "invalid_source",
      })
    );
  });

  it("6. Creation fails with extra fields", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertFails(
      docRef.set({
        blockedUserId: "user_bob",
        createdAt: new Date(),
        source: "profile",
        extraProperty: "hacked",
      })
    );
  });

  it("7. Creation fails on documentId and blockedUserId mismatch", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const docRef = aliceContext
      .firestore()
      .collection("users")
      .doc("user_alice")
      .collection("blockedUsers")
      .doc("user_bob");

    await assertFails(
      docRef.set({
        blockedUserId: "user_charlie", // Mismatch with doc ID user_bob
        createdAt: new Date(),
        source: "profile",
      })
    );
  });

  it("8. Direct client access to reports collection is completely denied", async () => {
    const aliceContext = testEnv.authenticatedContext("user_alice");
    const reportRef = aliceContext.firestore().collection("reports").doc("report_123");

    await assertFails(reportRef.get());
    await assertFails(
      reportRef.set({
        reporterId: "user_alice",
        targetType: "user",
        targetId: "user_bob",
      })
    );
  });

  it("9. UserRelations: Only listed users can read, client writes are completely denied", async () => {
    // Pre-populate relation via admin context (simulating Cloud Function)
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("userRelations").doc("rel_alice_bob").set({
        users: ["user_alice", "user_bob"],
        interactionBlocked: true,
        updatedAt: new Date(),
      });
    });

    const aliceContext = testEnv.authenticatedContext("user_alice");
    const bobContext = testEnv.authenticatedContext("user_bob");
    const charlieContext = testEnv.authenticatedContext("user_charlie");

    const relRefAlice = aliceContext.firestore().collection("userRelations").doc("rel_alice_bob");
    const relRefBob = bobContext.firestore().collection("userRelations").doc("rel_alice_bob");
    const relRefCharlie = charlieContext.firestore().collection("userRelations").doc("rel_alice_bob");

    // Listed users can read
    await assertSucceeds(relRefAlice.get());
    await assertSucceeds(relRefBob.get());

    // Unrelated user charlie CANNOT read
    await assertFails(relRefCharlie.get());

    // Client writes (create/update/delete) are strictly denied for all
    await assertFails(relRefAlice.set({ users: ["user_alice", "user_bob"], interactionBlocked: false }));
    await assertFails(relRefAlice.delete());
  });

  it("10. Draft Item Privacy: Draft items are ONLY readable by the lender", async () => {
    const aliceDb = testEnv.authenticatedContext("user_alice", { email_verified: true }).firestore();
    const bobDb = testEnv.authenticatedContext("user_bob", { email_verified: true }).firestore();

    const draftRefAlice = aliceDb.collection("items").doc("draft_item_1");
    const publicRefAlice = aliceDb.collection("items").doc("public_item_1");

    // Alice creates draft item
    await assertSucceeds(
      draftRefAlice.set({
        lenderId: "user_alice",
        status: "draft",
        createdAt: new Date(),
      })
    );

    // Alice creates public item
    await assertSucceeds(
      publicRefAlice.set({
        lenderId: "user_alice",
        title: "Public Item",
        description: "Public Description",
        status: "available",
        createdAt: new Date(),
      })
    );

    // Lender (alice) can read draft
    await assertSucceeds(draftRefAlice.get());

    // Non-lender (bob) CANNOT read draft
    await assertFails(bobDb.collection("items").doc("draft_item_1").get());

    // Non-lender (bob) CAN read public item
    await assertSucceeds(bobDb.collection("items").doc("public_item_1").get());
  });

  it("11. ChatMessage Block Enforcement: Blocked user CANNOT create a chat message", async () => {
    const aliceDb = testEnv.authenticatedContext("user_alice", { email_verified: true }).firestore();
    const bobDb = testEnv.authenticatedContext("user_bob", { email_verified: true }).firestore();

    // Alice creates item_1
    await assertSucceeds(
      aliceDb.collection("items").doc("item_1").set({
        lenderId: "user_alice",
        title: "Test Item",
        description: "Test Item Description",
        status: "available",
        createdAt: new Date(),
      })
    );

    // Bob creates borrow request to Alice's item_1 (before block)
    await assertSucceeds(
      bobDb.collection("borrowRequests").doc("req_123").set({
        ownerId: "user_alice",
        requesterId: "user_bob",
        itemId: "item_1",
        status: "accepted",
      })
    );

    // Alice blocks Bob
    await assertSucceeds(
      aliceDb
        .collection("users")
        .doc("user_alice")
        .collection("blockedUsers")
        .doc("user_bob")
        .set({
          blockedUserId: "user_bob",
          createdAt: new Date(),
          source: "profile",
        })
    );

    // Bob attempting to create message to Alice is DENIED by Security Rules
    await assertFails(
      bobDb.collection("chatMessages").doc("msg_999").set({
        requestId: "req_123",
        senderId: "user_bob",
        text: "Hello Alice",
        createdAt: new Date(),
      })
    );
  });
});

