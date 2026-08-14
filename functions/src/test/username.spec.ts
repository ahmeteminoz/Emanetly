import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { setUsername } from "../username_callable";
import { requestAccountDeletion } from "../account_deletion";

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

describe("v0.9.3 Username Privacy Suite", () => {
  let testEnv: RulesTestEnvironment;

  before(async () => {
    // Initialize Firestore Rules test environment
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

    // Initialize Admin SDK for functions testing
    if (!admin.apps.length) {
      process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
      admin.initializeApp({ projectId: "demo-emanetly" });
    }
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
    // Clear Admin Firestore collections
    const db = admin.firestore();
    const collections = ["users", "usernames", "accountDeletionJobs"];
    for (const col of collections) {
      const snap = await db.collection(col).get();
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
    try {
      await admin.auth().deleteUser("user_alice");
    } catch (_) {}
  });

  describe("1. Firestore Security Rules for Usernames & Profiles", () => {
    it("prevents client from reading or writing directly to /usernames collection", async () => {
      const aliceContext = testEnv.authenticatedContext("user_alice");
      const ref = aliceContext.firestore().collection("usernames").doc("alice77");

      await assertFails(ref.get());
      await assertFails(ref.set({ uid: "user_alice" }));
    });

    it("verifies initial profile creation requires correct legacy fields and empty username", async () => {
      const aliceContext = testEnv.authenticatedContext("user_alice");
      const ref = aliceContext.firestore().collection("users").doc("user_alice");

      // Fails with custom values or onboardingComplete == true
      await assertFails(ref.set({
        uid: "user_alice",
        username: "alice77",
        usernameNormalized: "alice77",
        usernameSource: "custom",
        onboardingComplete: true,
      }));

      // Succeeds with correct unset values
      await assertSucceeds(ref.set({
        uid: "user_alice",
        username: null,
        usernameNormalized: null,
        usernameSource: "unset",
        onboardingComplete: false,
        trustScore: 100,
        reviewCount: 0,
      }));
    });

    it("prevents client from updating username fields directly in users/{uid}", async () => {
      const aliceContext = testEnv.authenticatedContext("user_alice");
      const ref = aliceContext.firestore().collection("users").doc("user_alice");

      // Setup initial document via withSecurityRulesDisabled
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("user_alice").set({
          uid: "user_alice",
          username: null,
          usernameNormalized: null,
          usernameSource: "unset",
          onboardingComplete: false,
          trustScore: 100,
          reviewCount: 0,
          successfulBorrows: 0,
          successfulLends: 0,
          createdAt: new Date(),
        });
      });

      // Try updating direct username or source
      await assertFails(ref.update({ username: "alice_changed" }));
      await assertFails(ref.update({ onboardingComplete: true }));
      
      // Allowed updates to other fields like bio
      await assertSucceeds(ref.update({ bio: "New bio text" }));

      // Client CANNOT update userBadges (strict security rule check)
      await assertFails(ref.update({ userBadges: ["Süper Satıcı"] }));

      // Client CAN update notificationPreferences with correct keys and bool values
      await assertSucceeds(ref.update({
        notificationPreferences: {
          newMessages: false,
          newBorrowRequests: true,
        },
      }));

      // Client CANNOT update notificationPreferences with non-boolean values
      await assertFails(ref.update({
        notificationPreferences: {
          newMessages: "string",
          newBorrowRequests: true,
        },
      }));

      // Client CANNOT update notificationPreferences with missing keys (must have both)
      await assertFails(ref.update({
        notificationPreferences: {
          newMessages: true,
        },
      }));

      // Client CANNOT update notificationPreferences with extra keys
      await assertFails(ref.update({
        notificationPreferences: {
          newMessages: true,
          newBorrowRequests: false,
          extraKey: true,
        },
      }));
    });
  });

  describe("2. setUsername Callable Function Tests", () => {
    const invokeSetUsername = (username: any, auth?: any): Promise<any> => {
      const req: any = { data: { username } };
      if (auth !== undefined) {
        req.auth = auth;
      } else {
        req.auth = { uid: "user_alice", token: { email_verified: true } };
      }
      return (setUsername as any).run(req);
    };

    it("fails with unauthenticated when request.auth is missing", async () => {
      await assertFailsWithCode(
        invokeSetUsername("alice77", null),
        "unauthenticated"
      );
    });

    it("fails with failed-precondition when user is unverified", async () => {
      await assertFailsWithCode(
        invokeSetUsername("alice77", { uid: "user_alice", token: { email_verified: false } }),
        "failed-precondition"
      );
    });

    it("fails with not-found if users/{uid} document does not exist", async () => {
      await assertFailsWithCode(
        invokeSetUsername("alice77"),
        "not-found"
      );
    });

    it("fails with invalid-argument if format does not comply with regex", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({ uid: "user_alice", usernameSource: "unset", onboardingComplete: false });

      await assertFailsWithCode(invokeSetUsername(".alice"), "invalid-argument");
      await assertFailsWithCode(invokeSetUsername("alice_"), "invalid-argument");
      await assertFailsWithCode(invokeSetUsername("alice..oz"), "invalid-argument");
      await assertFailsWithCode(invokeSetUsername("al"), "invalid-argument"); // too short
      await assertFailsWithCode(invokeSetUsername("a".repeat(21)), "invalid-argument"); // too long
    });

    it("fails with invalid-argument if username matches reserved names or patterns", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({ uid: "user_alice", usernameSource: "unset", onboardingComplete: false });

      await assertFailsWithCode(invokeSetUsername("admin"), "invalid-argument");
      await assertFailsWithCode(invokeSetUsername("support_alice"), "invalid-argument");
      await assertFailsWithCode(invokeSetUsername("alice_emanetly_team"), "invalid-argument");
    });

    it("successfully transactionally claims a unique username and updates profile", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({
        uid: "user_alice",
        usernameSource: "unset",
        onboardingComplete: false,
      });

      const res = await invokeSetUsername("alice77");
      if (!res.success) throw new Error("Expected successful setUsername execution");

      // Verify claim doc exists
      const claimSnap = await db.collection("usernames").doc("alice77").get();
      if (!claimSnap.exists || claimSnap.data()?.uid !== "user_alice") {
        throw new Error("Claim document was not registered properly");
      }

      // Verify user document updated
      const userSnap = await db.collection("users").doc("user_alice").get();
      const userData = userSnap.data();
      if (userData?.username !== "alice77" || userData?.usernameNormalized !== "alice77" || userData?.usernameSource !== "custom" || userData?.onboardingComplete !== true) {
        throw new Error("User document did not update correctly with new custom username metadata");
      }
    });

    it("fails with already-exists if another user has claimed the username", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({ uid: "user_alice", usernameSource: "unset", onboardingComplete: false });
      await db.collection("users").doc("user_bob").set({ uid: "user_bob", usernameSource: "unset", onboardingComplete: false });

      // Alice claims it first
      await invokeSetUsername("alice77");

      // Bob tries to claim the same one
      await assertFailsWithCode(
        invokeSetUsername("alice77", { uid: "user_bob", token: { email_verified: true } }),
        "already-exists"
      );
    });

    it("prevents changing username if user has already custom username and is onboarded", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({
        uid: "user_alice",
        username: "alice77",
        usernameNormalized: "alice77",
        usernameSource: "custom",
        onboardingComplete: true,
      });
      await db.collection("usernames").doc("alice77").set({ uid: "user_alice" });

      await assertFailsWithCode(
        invokeSetUsername("newalice"),
        "failed-precondition"
      );
    });

    it("performs a safe idempotent no-op when calling setUsername with the same value during migration", async () => {
      const db = admin.firestore();
      await db.collection("users").doc("user_alice").set({
        uid: "user_alice",
        username: "alice77",
        usernameNormalized: "alice77",
        usernameSource: "legacy",
        onboardingComplete: false,
      });
      await db.collection("usernames").doc("alice77").set({ uid: "user_alice" });

      const res = await invokeSetUsername("alice77");
      if (!res.success || !res.idempotent) {
        throw new Error("Expected successful idempotent no-op response");
      }
    });
  });

  describe("3. Account Deletion Claim Cleanup", () => {
    it("idempotently cleans up claimed username document and verifies ownership during account deletion", async () => {
      const db = admin.firestore();
      
      // Setup user and claim
      await db.collection("users").doc("user_alice").set({
        uid: "user_alice",
        usernameNormalized: "alice77",
        onboardingComplete: true,
      });
      await db.collection("usernames").doc("alice77").set({ uid: "user_alice" });
      
      // Create user in Auth emulator so deleteUser doesn't throw auth/user-not-found
      await admin.auth().createUser({ uid: "user_alice", email: "alice@yildiz.edu.tr" });

      // Setup deletion job
      const jobRef = db.collection("accountDeletionJobs").doc("user_alice");
      await jobRef.set({ status: "running", stage_blocked_cleaned: false });

      // Run deletion function directly (simulating Step 5)
      const req = { auth: { uid: "user_alice" } };
      await (requestAccountDeletion as any).run(req);

      // Verify claim doc is deleted
      const claimSnap = await db.collection("usernames").doc("alice77").get();
      if (claimSnap.exists) {
        throw new Error("Expected username claim document to be deleted during account deletion");
      }
    });
  });
});
