import firebaseFunctionsTest from "firebase-functions-test";
import { resolve } from "path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
// Set a dummy project ID so initializeApp doesn't complain
process.env.GCLOUD_PROJECT = "amen-b2dc0";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "amen-b2dc0" });

const myTestEnv = firebaseFunctionsTest({ projectId: "amen-b2dc0" });
import * as myFunctions from "../src/index";

afterAll(() => {
  myTestEnv.cleanup();
});

describe("Cloud Functions", () => {
  describe("createIntention", () => {
    it("should throw if unauthenticated", async () => {
      const wrapped = myTestEnv.wrap(myFunctions.createIntention);
      await expect(wrapped({ data: { text: "Hello" } })).rejects.toThrow("Anonymous auth is required.");
    });

    it("should throw if text is missing or invalid", async () => {
      const wrapped = myTestEnv.wrap(myFunctions.createIntention);
      await expect(wrapped({ auth: { uid: "alice" }, data: {} })).rejects.toThrow("Text is required.");
      await expect(wrapped({ auth: { uid: "alice" }, data: { text: "   " } })).rejects.toThrow("Text must be 1-250 characters.");
      await expect(wrapped({ auth: { uid: "alice" }, data: { text: "fuck" } })).rejects.toThrow("Text did not pass moderation.");
    });

    it("should create an intention", async () => {
      const wrapped = myTestEnv.wrap(myFunctions.createIntention);
      const res = await wrapped({ auth: { uid: "alice" }, data: { text: "Pray for peace." } });
      expect(res.id).toBeDefined();
    });
  });

  describe("sayAmen", () => {
    it("should throw if unauthenticated", async () => {
      const wrapped = myTestEnv.wrap(myFunctions.sayAmen);
      await expect(wrapped({ data: { intentionId: "123" } })).rejects.toThrow("Anonymous auth is required.");
    });

    it("should throw if intentionId is missing", async () => {
      const wrapped = myTestEnv.wrap(myFunctions.sayAmen);
      await expect(wrapped({ auth: { uid: "alice" }, data: {} })).rejects.toThrow("intentionId is required.");
    });
  });

  describe("pinIntention", () => {
    it("should throw if unauthenticated", async () => {
      const wrapped = myTestEnv.wrap(myFunctions.pinIntention);
      await expect(wrapped({ data: { intentionId: "123" } })).rejects.toThrow("Anonymous auth is required.");
    });
  });
});
