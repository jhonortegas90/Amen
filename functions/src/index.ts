import {initializeApp} from "firebase-admin/app";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();

const db = getFirestore();
const blockedTerms = /\b(fuck|shit|bitch|asshole|kill yourself|suicide bait|hate|slur|racist)\b/i;

function requireUid(auth?: {uid?: string}): string {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Anonymous auth is required.");
  }
  return uid;
}

function cleanText(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Text is required.");
  }
  const text = value.trim();
  if (!text || text.length > 250) {
    throw new HttpsError("invalid-argument", "Text must be 1-250 characters.");
  }
  if (blockedTerms.test(text)) {
    throw new HttpsError("failed-precondition", "Text did not pass moderation safety checks.");
  }
  return text;
}

export const createIntention = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const text = cleanText(request.data?.text);
  const category = typeof request.data?.category === "string" ? request.data.category : "general";
  const locale = typeof request.data?.locale === "string" ? request.data.locale : "en";

  const doc = db.collection("intentions").doc();
  await doc.set({
    authorUid: uid,
    text,
    category,
    createdAt: FieldValue.serverTimestamp(),
    amenCount: 0,
    isPinned: false,
    pinnedUntil: null,
    locale,
    status: "approved",
    schemaVersion: 1,
  });

  return {id: doc.id};
});

export const reportIntention = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const intentionId = String(request.data?.intentionId ?? "");
  const reason = String(request.data?.reason ?? "Other Safety Concern");

  if (!intentionId) {
    throw new HttpsError("invalid-argument", "intentionId is required.");
  }

  const reportDoc = db.collection("reports").doc();
  await reportDoc.set({
    intentionId,
    reporterUid: uid,
    reason,
    status: "pending_review",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Flag intention for review if multiple reports exist
  const existingReports = await db
    .collection("reports")
    .where("intentionId", "==", intentionId)
    .get();

  if (existingReports.size >= 2) {
    await db.collection("intentions").doc(intentionId).update({
      status: "flagged_under_review",
    });
  }

  return {id: reportDoc.id, ok: true};
});

export const sayAmen = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const intentionId = String(request.data?.intentionId ?? "");
  if (!intentionId) {
    throw new HttpsError("invalid-argument", "intentionId is required.");
  }

  const intentionRef = db.collection("intentions").doc(intentionId);
  const eventRef = db.collection("amen_events").doc(`${intentionId}_${uid}`);

  const authorUid = await db.runTransaction(async (transaction) => {
    const [intentionSnap, eventSnap] = await Promise.all([
      transaction.get(intentionRef),
      transaction.get(eventRef),
    ]);
    if (!intentionSnap.exists) {
      throw new HttpsError("not-found", "Prayer not found.");
    }
    if (eventSnap.exists) {
      return null;
    }
    const data = intentionSnap.data() ?? {};
    transaction.set(eventRef, {
      intentionId,
      uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(intentionRef, {
      amenCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return data.authorUid as string | undefined;
  });

  if (authorUid && authorUid !== uid) {
    await notifyAuthor(authorUid);
  }

  return {ok: true};
});

export const pinIntention = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const intentionId = String(request.data?.intentionId ?? "");
  if (!intentionId) {
    throw new HttpsError("invalid-argument", "intentionId is required.");
  }

  const ref = db.collection("intentions").doc(intentionId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Prayer not found.");
  }
  if (snap.data()?.authorUid !== uid) {
    throw new HttpsError("permission-denied", "Only the author can pin this prayer.");
  }

  await ref.update({
    isPinned: true,
    pinnedUntil: Timestamp.fromMillis(Date.now() + 2 * 60 * 60 * 1000),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {ok: true};
});

export const expirePinnedIntentions = onSchedule("every 15 minutes", async () => {
  const expired = await db
    .collection("intentions")
    .where("isPinned", "==", true)
    .where("pinnedUntil", "<=", Timestamp.now())
    .limit(100)
    .get();

  const batch = db.batch();
  expired.docs.forEach((doc) => {
    batch.update(doc.ref, {isPinned: false});
  });
  await batch.commit();
});

async function notifyAuthor(authorUid: string): Promise<void> {
  const tokens = await db
    .collection("device_tokens")
    .doc(authorUid)
    .collection("tokens")
    .limit(20)
    .get();

  const payloads = tokens.docs.map((doc) => {
    const data = doc.data();
    const locale = String(data.locale ?? "en");
    return {
      docId: doc.id,
      message: {
        token: String(data.token ?? doc.id),
        notification: {
          title: "Amen",
          body: notificationBody(locale),
        },
        data: {
          type: "amen_received",
        },
      },
    };
  });

  await Promise.all(
    payloads.map(async ({docId, message}) => {
      try {
        await getMessaging().send(message);
      } catch (error: any) {
        if (
          error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered"
        ) {
          await db
            .collection("device_tokens")
            .doc(authorUid)
            .collection("tokens")
            .doc(docId)
            .delete();
        }
      }
    }),
  );
}

function notificationBody(locale: string): string {
  if (locale.startsWith("es")) return "Alguien acaba de decir Amén a tu oración.";
  if (locale.startsWith("fr")) return "Quelqu’un vient de dire Amen à ta prière.";
  return "Someone just said Amen to your prayer.";
}
