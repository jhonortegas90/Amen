import { describe, it, beforeAll, afterAll, expect, beforeEach, vi } from "vitest";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import functionsTest from "firebase-functions-test";

vi.mock("firebase-admin/messaging", () => {
  return {
    getMessaging: vi.fn(() => ({
      send: vi.fn(async () => "mock-message-id"),
    })),
  };
});

import * as myFunctions from "../src/index";

const testEnv = functionsTest({
  projectId: "amen-b2dc0",
});

describe("Cloud Functions", () => {
  let db: ReturnType<typeof getFirestore>;

  beforeAll(() => {
    if (getApps().length === 0) {
      initializeApp({ projectId: "amen-b2dc0" });
    }
    db = getFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    const apps = getApps();
    await Promise.all(apps.map((app) => deleteApp(app)));
  });

  beforeEach(async () => {
    // Clear Firestore
    const collections = await db.listCollections();
    for (const collection of collections) {
      const docs = await collection.get();
      const batch = db.batch();
      docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  describe("createIntention", () => {
    it("should require auth", async () => {
      const wrapped = testEnv.wrap(myFunctions.createIntention);
      await expect(wrapped({ data: { text: "Hello" } })).rejects.toThrow("Anonymous auth is required.");
    });

    it("should clean text and create intention", async () => {
      const wrapped = testEnv.wrap(myFunctions.createIntention);
      const res = await wrapped({
        data: { text: "  My prayer  " },
        auth: { uid: "user1" },
      });

      expect(res.id).toBeDefined();
      const doc = await db.collection("intentions").doc(res.id).get();
      expect(doc.exists).toBe(true);
      expect(doc.data()?.text).toBe("My prayer");
      expect(doc.data()?.authorUid).toBe("user1");
    });
  });

  describe("sayAmen", () => {
    it("should increment amenCount and prevent duplicates", async () => {
      // Create intention
      const intentionRef = db.collection("intentions").doc("intent-1");
      await intentionRef.set({
        authorUid: "user1",
        text: "Pray for peace",
        amenCount: 0,
      });

      const wrapped = testEnv.wrap(myFunctions.sayAmen);
      
      // First amen by user2
      await wrapped({
        data: { intentionId: "intent-1" },
        auth: { uid: "user2" },
      });

      let doc = await intentionRef.get();
      expect(doc.data()?.amenCount).toBe(1);

      // Duplicate amen by user2 should not increment
      await wrapped({
        data: { intentionId: "intent-1" },
        auth: { uid: "user2" },
      });

      doc = await intentionRef.get();
      expect(doc.data()?.amenCount).toBe(1);
    });
  });

  describe("pinIntention", () => {
    it("should allow author to pin", async () => {
      const intentionRef = db.collection("intentions").doc("intent-1");
      await intentionRef.set({
        authorUid: "user1",
        text: "Pray for peace",
        isPinned: false,
      });

      const wrapped = testEnv.wrap(myFunctions.pinIntention);
      
      await wrapped({
        data: { intentionId: "intent-1" },
        auth: { uid: "user1" },
      });

      const doc = await intentionRef.get();
      expect(doc.data()?.isPinned).toBe(true);
      expect(doc.data()?.pinnedUntil).toBeDefined();
    });

    it("should prevent non-author from pinning", async () => {
      const intentionRef = db.collection("intentions").doc("intent-1");
      await intentionRef.set({
        authorUid: "user1",
        text: "Pray for peace",
        isPinned: false,
      });

      const wrapped = testEnv.wrap(myFunctions.pinIntention);
      
      await expect(wrapped({
        data: { intentionId: "intent-1" },
        auth: { uid: "user2" },
      })).rejects.toThrow("Only the author can pin this prayer.");
    });
  });
});
