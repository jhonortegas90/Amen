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

    it("prevents client-created intentions", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();

      await assertFails(
        alice.collection("intentions").doc("intent-1").set({
          authorUid: "alice",
          text: "Hello",
          amenCount: 0,
          isPinned: false,
          status: "approved",
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

  describe("notifications", () => {
    it("prevents client-created notifications", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();

      await assertFails(
        alice.collection("notifications").doc("notification-1").set({
          recipientUid: "bob",
          senderUid: "alice",
          type: "supportMessage",
          isRead: false,
        })
      );
    });

    it("allows recipients to mark only isRead", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("notifications").doc("notification-1").set({
          recipientUid: "alice",
          senderUid: "bob",
          type: "supportMessage",
          isRead: false,
        });
      });

      await assertSucceeds(
        alice.collection("notifications").doc("notification-1").update({
          isRead: true,
        })
      );

      await assertFails(
        alice.collection("notifications").doc("notification-1").update({
          messageText: "changed",
        })
      );
    });
  });

  describe("reports", () => {
    it("prevents client-created reports", async () => {
      const alice = testEnv.authenticatedContext("alice").firestore();

      await assertFails(
        alice.collection("reports").doc("report-1").set({
          intentionId: "intent-1",
          reporterUid: "alice",
          reason: "Spam",
        })
      );
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

  describe("prayer catalog", () => {
    it("allows public reads for published catalog content", async () => {
      const db = testEnv.unauthenticatedContext().firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context
          .firestore()
          .collection("prayer_catalog_published")
          .doc("en")
          .collection("prayers")
          .doc("prayer-1")
          .set({
            title: "Published",
            isActive: true,
          });
      });

      await assertSucceeds(
        db
          .collection("prayer_catalog_published")
          .doc("en")
          .collection("prayers")
          .doc("prayer-1")
          .get()
      );
    });

    it("allows only catalog admins to write draft catalog content", async () => {
      const admin = testEnv.authenticatedContext("admin", {
        catalogAdmin: true,
        email: "j.a.t.creativestudios@gmail.com",
      }).firestore();
      const user = testEnv.authenticatedContext("user").firestore();

      await assertSucceeds(
        admin
          .collection("prayer_catalog_drafts")
          .doc("shared")
          .collection("categories")
          .doc("cat-1")
          .set({
            sortOrder: 1,
            isActive: true,
          })
      );

      await assertFails(
        user
          .collection("prayer_catalog_drafts")
          .doc("shared")
          .collection("categories")
          .doc("cat-2")
          .set({
            sortOrder: 2,
            isActive: true,
          })
      );
    });

    it("denies access to catalog admins with a different email", async () => {
      const wrongAdmin = testEnv.authenticatedContext("wrongAdmin", {
        catalogAdmin: true,
        email: "not.admin@gmail.com",
      }).firestore();

      await assertFails(
        wrongAdmin
          .collection("prayer_catalog_drafts")
          .doc("shared")
          .collection("categories")
          .doc("cat-3")
          .set({
            sortOrder: 3,
            isActive: true,
          })
      );
    });

    it("blocks client writes to published catalog content", async () => {
      const admin = testEnv.authenticatedContext("admin", {
        catalogAdmin: true,
        email: "j.a.t.creativestudios@gmail.com",
      }).firestore();

      await assertFails(
        admin
          .collection("prayer_catalog_published")
          .doc("en")
          .collection("prayers")
          .doc("prayer-1")
          .set({
            title: "No direct publish",
          })
      );
    });

    it("restricts catalog audit reads to catalog admins", async () => {
      const admin = testEnv.authenticatedContext("admin", {
        catalogAdmin: true,
        email: "j.a.t.creativestudios@gmail.com",
      }).firestore();
      const user = testEnv.authenticatedContext("user").firestore();

      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("catalog_admin_audit").doc("audit-1").set({
          action: "publishPrayerCatalog",
        });
      });

      await assertSucceeds(admin.collection("catalog_admin_audit").doc("audit-1").get());
      await assertFails(user.collection("catalog_admin_audit").doc("audit-1").get());
    });
  });
});
