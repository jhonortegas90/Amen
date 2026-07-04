"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.expirePinnedIntentions = exports.pinIntention = exports.sayAmen = exports.reportIntention = exports.createIntention = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const blockedTerms = /\b(fuck|shit|bitch|asshole|kill yourself|suicide bait|hate|slur|racist)\b/i;
function requireUid(auth) {
    const uid = auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "Anonymous auth is required.");
    }
    return uid;
}
function cleanText(value) {
    if (typeof value !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Text is required.");
    }
    const text = value.trim();
    if (!text || text.length > 250) {
        throw new https_1.HttpsError("invalid-argument", "Text must be 1-250 characters.");
    }
    if (blockedTerms.test(text)) {
        throw new https_1.HttpsError("failed-precondition", "Text did not pass moderation safety checks.");
    }
    return text;
}
exports.createIntention = (0, https_1.onCall)(async (request) => {
    const uid = requireUid(request.auth);
    const text = cleanText(request.data?.text);
    const category = typeof request.data?.category === "string" ? request.data.category : "general";
    const locale = typeof request.data?.locale === "string" ? request.data.locale : "en";
    const doc = db.collection("intentions").doc();
    await doc.set({
        authorUid: uid,
        text,
        category,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        amenCount: 0,
        isPinned: false,
        pinnedUntil: null,
        locale,
        status: "approved",
        schemaVersion: 1,
    });
    return { id: doc.id };
});
exports.reportIntention = (0, https_1.onCall)(async (request) => {
    const uid = requireUid(request.auth);
    const intentionId = String(request.data?.intentionId ?? "");
    const reason = String(request.data?.reason ?? "Other Safety Concern");
    if (!intentionId) {
        throw new https_1.HttpsError("invalid-argument", "intentionId is required.");
    }
    const reportDoc = db.collection("reports").doc();
    await reportDoc.set({
        intentionId,
        reporterUid: uid,
        reason,
        status: "pending_review",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
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
    return { id: reportDoc.id, ok: true };
});
exports.sayAmen = (0, https_1.onCall)(async (request) => {
    const uid = requireUid(request.auth);
    const intentionId = String(request.data?.intentionId ?? "");
    if (!intentionId) {
        throw new https_1.HttpsError("invalid-argument", "intentionId is required.");
    }
    const intentionRef = db.collection("intentions").doc(intentionId);
    const eventRef = db.collection("amen_events").doc(`${intentionId}_${uid}`);
    const authorUid = await db.runTransaction(async (transaction) => {
        const [intentionSnap, eventSnap] = await Promise.all([
            transaction.get(intentionRef),
            transaction.get(eventRef),
        ]);
        if (!intentionSnap.exists) {
            throw new https_1.HttpsError("not-found", "Prayer not found.");
        }
        if (eventSnap.exists) {
            return null;
        }
        const data = intentionSnap.data() ?? {};
        transaction.set(eventRef, {
            intentionId,
            uid,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        transaction.update(intentionRef, {
            amenCount: firestore_1.FieldValue.increment(1),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        return data.authorUid;
    });
    if (authorUid && authorUid !== uid) {
        await notifyAuthor(authorUid);
    }
    return { ok: true };
});
exports.pinIntention = (0, https_1.onCall)(async (request) => {
    const uid = requireUid(request.auth);
    const intentionId = String(request.data?.intentionId ?? "");
    if (!intentionId) {
        throw new https_1.HttpsError("invalid-argument", "intentionId is required.");
    }
    const ref = db.collection("intentions").doc(intentionId);
    const snap = await ref.get();
    if (!snap.exists) {
        throw new https_1.HttpsError("not-found", "Prayer not found.");
    }
    if (snap.data()?.authorUid !== uid) {
        throw new https_1.HttpsError("permission-denied", "Only the author can pin this prayer.");
    }
    await ref.update({
        isPinned: true,
        pinnedUntil: firestore_1.Timestamp.fromMillis(Date.now() + 2 * 60 * 60 * 1000),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { ok: true };
});
exports.expirePinnedIntentions = (0, scheduler_1.onSchedule)("every 15 minutes", async () => {
    const expired = await db
        .collection("intentions")
        .where("isPinned", "==", true)
        .where("pinnedUntil", "<=", firestore_1.Timestamp.now())
        .limit(100)
        .get();
    const batch = db.batch();
    expired.docs.forEach((doc) => {
        batch.update(doc.ref, { isPinned: false });
    });
    await batch.commit();
});
async function notifyAuthor(authorUid) {
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
    await Promise.all(payloads.map(async ({ docId, message }) => {
        try {
            await (0, messaging_1.getMessaging)().send(message);
        }
        catch (error) {
            if (error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered") {
                await db
                    .collection("device_tokens")
                    .doc(authorUid)
                    .collection("tokens")
                    .doc(docId)
                    .delete();
            }
        }
    }));
}
function notificationBody(locale) {
    if (locale.startsWith("es"))
        return "Alguien acaba de decir Amén a tu oración.";
    if (locale.startsWith("fr"))
        return "Quelqu’un vient de dire Amen à ta prière.";
    return "Someone just said Amen to your prayer.";
}
//# sourceMappingURL=index.js.map