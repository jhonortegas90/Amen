import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, beforeAll, afterAll, beforeEach, it } from "vitest";

let testEnv: RulesTestEnvironment;

describe("Firestore Security Rules", () => {
  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: "amen-b2dc0-test",
      firestore: {
        rules: readFileSync(resolve(__dirname, "../../firestore.rules"), "utf8"),
        host: "127.0.0.1",
        port: 8080,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  describe("intentions", () => {
    it("allows anyone to read approved intentions", async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      
      // We must mock the approved document using an admin context
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("intentions").doc("approved-1").set({
          status: "approved",
        });
        await context.firestore().collection("intentions").doc("pending-1").set({
          status: "pending",
        });
      });

      await assertSucceeds(db.collection("intentions").doc("approved-1").get());
      await assertFails(db.collection("intentions").doc("pending-1").get());
    });

    it("prevents users from impersonating another authorUid on create", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();

      await assertFails(
        alice.collection("intentions").doc("intent-1").set({
          authorUid: "bob",
          text: "Hello",
          amenCount: 0,
          isPinned: false,
          status: "pending",
        })
      );

      await assertSucceeds(
        alice.collection("intentions").doc("intent-2").set({
          authorUid: "alice",
          text: "Hello",
          amenCount: 0,
          isPinned: false,
          status: "pending",
        })
      );
    });

    it("prevents users from updating or deleting intentions directly", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("intentions").doc("alice-intent").set({
          authorUid: "alice",
          text: "Hello",
          amenCount: 0,
          isPinned: false,
          status: "approved",
        });
      });

      await assertFails(
        alice.collection("intentions").doc("alice-intent").update({
          amenCount: 100,
        })
      );

      await assertFails(alice.collection("intentions").doc("alice-intent").delete());
    });
  });

  describe("device_tokens", () => {
    it("prevents reading tokens", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();
      
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("device_tokens").doc("alice").collection("tokens").doc("token-1").set({
          token: "token-1",
        });
      });

      await assertFails(
        alice.collection("device_tokens").doc("alice").collection("tokens").doc("token-1").get()
      );
    });

    it("allows users to write their own tokens", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();
      const bob = testEnv.authenticatedContext("bob").firestore();

      await assertSucceeds(
        alice.collection("device_tokens").doc("alice").collection("tokens").doc("token-1").set({
          token: "token-1",
        })
      );

      await assertFails(
        bob.collection("device_tokens").doc("alice").collection("tokens").doc("token-2").set({
          token: "token-2",
        })
      );
    });
  });
});
