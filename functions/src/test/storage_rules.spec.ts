import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import * as fs from "fs";
import * as path from "path";
import * as admin from "firebase-admin";

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_STORAGE_EMULATOR_HOST = "127.0.0.1:9199";

describe("Storage Security Rules - Moderation & Items (v0.9.0)", () => {
  let testEnv: RulesTestEnvironment;

  let db: admin.firestore.Firestore;

  before(async () => {
    const firestoreRules = fs.readFileSync(path.resolve(__dirname, "../../../firestore.rules"), "utf8");
    const storageRules = fs.readFileSync(path.resolve(__dirname, "../../../storage.rules"), "utf8");

    if (!admin.apps.length) {
      admin.initializeApp({ projectId: "demo-emanetly" });
    }
    db = admin.firestore();

    testEnv = await initializeTestEnvironment({
      projectId: "demo-emanetly",
      firestore: {
        rules: firestoreRules,
        host: "127.0.0.1",
        port: 8080,
      },
      storage: {
        rules: storageRules,
        host: "127.0.0.1",
        port: 9199,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.clearStorage();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  it("1. Owner can upload image when draft item exists in Firestore", async () => {
    await db.collection("items").doc("item123").set({
      lenderId: "lender1",
      status: "draft",
      createdAt: new Date(),
    });

    const lenderContext = testEnv.authenticatedContext("lender1");
    const storage = lenderContext.storage();
    const fileRef = storage.ref("items/item123/photo.jpg");

    const dummyImageBytes = Buffer.from("fake-image-bytes");
    await assertSucceeds(
      Promise.resolve(fileRef.put(dummyImageBytes, { contentType: "image/jpeg" }))
    );
  });

  it("2. Non-owner upload is strictly denied", async () => {
    await db.collection("items").doc("item123").set({
      lenderId: "lender1",
      status: "draft",
      createdAt: new Date(),
    });

    const intruderContext = testEnv.authenticatedContext("intruder99");
    const storage = intruderContext.storage();
    const fileRef = storage.ref("items/item123/photo.jpg");

    const dummyImageBytes = Buffer.from("fake-image-bytes");
    await assertFails(
      Promise.resolve(fileRef.put(dummyImageBytes, { contentType: "image/jpeg" }))
    );
  });

  it("3. Upload fails if item document does not exist in Firestore", async () => {
    const lenderContext = testEnv.authenticatedContext("lender1");
    const storage = lenderContext.storage();
    const fileRef = storage.ref("items/nonexistentItem/photo.jpg");

    const dummyImageBytes = Buffer.from("fake-image-bytes");
    await assertFails(
      Promise.resolve(fileRef.put(dummyImageBytes, { contentType: "image/jpeg" }))
    );
  });

  it("4. Non-image content type is rejected", async () => {
    await db.collection("items").doc("item123").set({
      lenderId: "lender1",
      status: "draft",
      createdAt: new Date(),
    });

    const lenderContext = testEnv.authenticatedContext("lender1");
    const storage = lenderContext.storage();
    const fileRef = storage.ref("items/item123/document.pdf");

    const dummyBytes = Buffer.from("fake-pdf-bytes");
    await assertFails(
      Promise.resolve(fileRef.put(dummyBytes, { contentType: "application/pdf" }))
    );
  });

  it("5. Files exceeding 8 MB size limit are rejected", async () => {
    await db.collection("items").doc("item123").set({
      lenderId: "lender1",
      status: "draft",
      createdAt: new Date(),
    });

    const lenderContext = testEnv.authenticatedContext("lender1");
    const storage = lenderContext.storage();
    const fileRef = storage.ref("items/item123/huge.jpg");

    const hugeBuffer = Buffer.alloc(9 * 1024 * 1024);
    await assertFails(
      Promise.resolve(fileRef.put(hugeBuffer, { contentType: "image/jpeg" }))
    );
  });
});
