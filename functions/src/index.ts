import * as functions from "firebase-functions/v1";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {getStorage} from "firebase-admin/storage";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();

const db = getFirestore();
const storage = getStorage();
const blockedTerms = /\b(fuck|shit|bitch|asshole|kill yourself|suicide bait|hate|slur|racist)\b/i;
const supportedCatalogLocales = new Set(["en", "es", "fr"]);
const initialCatalogAdminEmail = "j.a.t.creativestudios@gmail.com";

function requireUid(auth?: {uid?: string}): string {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Anonymous auth is required.");
  }
  return uid;
}

function requireCatalogAdmin(auth?: {uid?: string; token?: Record<string, unknown>}): string {
  const uid = requireUid(auth);
  if (auth?.token?.catalogAdmin !== true || auth?.token?.email !== initialCatalogAdminEmail) {
    throw new HttpsError("permission-denied", "Catalog admin access is required.");
  }
  return uid;
}

function cleanLocale(value: unknown): string {
  const locale = typeof value === "string" ? value.toLowerCase().split(/[-_]/)[0] : "en";
  if (!supportedCatalogLocales.has(locale)) {
    throw new HttpsError("invalid-argument", "Unsupported catalog locale.");
  }
  return locale;
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

function cleanSupportMessage(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Message text is required.");
  }
  const text = value.trim();
  if (!text || text.length > 250) {
    throw new HttpsError("invalid-argument", "Message text must be 1-250 characters.");
  }
  if (blockedTerms.test(text)) {
    throw new HttpsError("failed-precondition", "Message text did not pass moderation safety checks.");
  }
  return text;
}

function cleanSenderName(value: unknown): string {
  if (typeof value !== "string") {
    return "A Brother/Sister in Faith";
  }
  const name = value.trim();
  if (!name) {
    return "A Brother/Sister in Faith";
  }
  return name.slice(0, 60);
}

export const createIntention = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const text = cleanText(request.data?.text);
  const category = typeof request.data?.category === "string" ? request.data.category : "general";
  const locale = typeof request.data?.locale === "string" ? request.data.locale : "en";
  const isAnonymous = request.data?.isAnonymous !== false;

  let authorName: string | null = null;
  let authorAvatarUrl: string | null = null;

  if (!isAnonymous) {
    try {
      const user = await getAuth().getUser(uid);
      authorName = user.displayName || null;
      authorAvatarUrl = user.photoURL || null;
    } catch (e) {
      // Ignore auth lookups if they fail
    }
  }

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
    isAnonymous,
    authorName,
    authorAvatarUrl,
  });

  return {id: doc.id};
});

export const onDeleteUser = functions.auth.user().onDelete(async (user: any) => {
  const uid = user.uid;
  const batch = db.batch();

  // 1. Delete device tokens
  const tokensSnap = await db.collection("device_tokens").doc(uid).collection("tokens").get();
  tokensSnap.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  batch.delete(db.collection("device_tokens").doc(uid));

  // 2. Delete notifications (recipientUid == uid or senderUid == uid)
  const recipientNotifs = await db.collection("notifications").where("recipientUid", "==", uid).get();
  recipientNotifs.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  const senderNotifs = await db.collection("notifications").where("senderUid", "==", uid).get();
  senderNotifs.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
});

export const bootstrapCatalogAdmin = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const user = await getAuth().getUser(uid);
  const email = user.email?.toLowerCase().trim();
  if (email !== initialCatalogAdminEmail) {
    throw new HttpsError("permission-denied", "This account cannot bootstrap catalog admin access.");
  }

  await getAuth().setCustomUserClaims(uid, {
    ...(user.customClaims ?? {}),
    catalogAdmin: true,
  });

  await db.collection("catalog_admin_audit").add({
    action: "bootstrapCatalogAdmin",
    uid,
    email,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {ok: true};
});

export const setCatalogAdmin = onCall(async (request) => {
  const uid = requireCatalogAdmin(request.auth);
  const email = String(request.data?.email ?? "").toLowerCase().trim();
  const enabled = request.data?.enabled !== false;
  if (!email) {
    throw new HttpsError("invalid-argument", "email is required.");
  }

  const user = await getAuth().getUserByEmail(email);
  await getAuth().setCustomUserClaims(user.uid, {
    ...(user.customClaims ?? {}),
    catalogAdmin: enabled,
  });

  await db.collection("catalog_admin_audit").add({
    action: enabled ? "setCatalogAdmin" : "removeCatalogAdmin",
    actorUid: uid,
    targetUid: user.uid,
    email,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {ok: true, uid: user.uid};
});

export const validatePrayerCatalogDraft = onCall(async (request) => {
  requireCatalogAdmin(request.auth);
  const locale = cleanLocale(request.data?.locale);
  const result = await validateDraft(locale);
  return result;
});

export const publishPrayerCatalog = onCall(async (request) => {
  const uid = requireCatalogAdmin(request.auth);
  const locale = cleanLocale(request.data?.locale);
  const validation = await validateDraft(locale);
  if (validation.errors.length > 0) {
    return validation;
  }

  const [sharedCategoriesSnap, sharedPrayersSnap, localeCategoriesSnap, localePrayersSnap] =
    await Promise.all([
      db.collection("prayer_catalog_drafts/shared/categories").get(),
      db.collection("prayer_catalog_drafts/shared/prayers").get(),
      db.collection(`prayer_catalog_drafts/${locale}/categories`).get(),
      db.collection(`prayer_catalog_drafts/${locale}/prayers`).get(),
    ]);

  const localeCategories = new Map(localeCategoriesSnap.docs.map((doc) => [doc.id, doc.data()]));
  const localePrayers = new Map(localePrayersSnap.docs.map((doc) => [doc.id, doc.data()]));
  const activeCategoryIds = new Set(
    sharedCategoriesSnap.docs
      .filter((doc) => doc.data().isActive !== false)
      .map((doc) => doc.id),
  );
  const categoryTitles = new Map(
    sharedCategoriesSnap.docs.map((doc) => {
      const text = localeCategories.get(doc.id) ?? {};
      return [doc.id, {
        title: cleanString(text.title, "Untitled catalog"),
        description: cleanString(text.description, ""),
      }];
    }),
  );

  const bucket = storage.bucket();
  const publishedCategoryDocs = await db
    .collection(`prayer_catalog_published/${locale}/categories`)
    .get();
  const publishedPrayerDocs = await db
    .collection(`prayer_catalog_published/${locale}/prayers`)
    .get();

  const batch = db.batch();
  for (const doc of publishedCategoryDocs.docs) {
    batch.delete(doc.ref);
  }
  for (const doc of publishedPrayerDocs.docs) {
    batch.delete(doc.ref);
  }

  for (const doc of sharedCategoriesSnap.docs) {
    const shared = doc.data();
    if (shared.isActive === false) continue;
    const text = localeCategories.get(doc.id) ?? {};
    const media = await publishMedia(
      bucket,
      cleanString(shared.backgroundImagePath, ""),
      `prayer_catalog/published/${locale}/categories/${doc.id}/background`,
    );
    batch.set(db.doc(`prayer_catalog_published/${locale}/categories/${doc.id}`), {
      id: doc.id,
      title: cleanString(text.title, "Untitled catalog"),
      description: cleanString(text.description, ""),
      sortOrder: Number(shared.sortOrder ?? 0),
      isActive: true,
      backgroundImagePath: media.path || null,
      backgroundImageUrl: media.url || null,
      createdAt: shared.createdAt ?? FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
  }

  for (const doc of sharedPrayersSnap.docs) {
    const shared = doc.data();
    const categoryId = cleanString(shared.categoryId, "");
    if (shared.isActive === false || !activeCategoryIds.has(categoryId)) continue;
    const text = localePrayers.get(doc.id) ?? {};
    const categoryText = categoryTitles.get(categoryId) ?? {
      title: "Prayer",
      description: "",
    };
    const background = await publishMedia(
      bucket,
      cleanString(shared.backgroundImagePath, ""),
      `prayer_catalog/published/${locale}/prayers/${doc.id}/background`,
    );
    const audio = await publishMedia(
      bucket,
      cleanString(shared.audioPath, ""),
      `prayer_catalog/published/${locale}/prayers/${doc.id}/audio`,
    );
    batch.set(db.doc(`prayer_catalog_published/${locale}/prayers/${doc.id}`), {
      id: doc.id,
      categoryId,
      categoryTitle: categoryText.title,
      categoryDescription: categoryText.description,
      title: cleanString(text.title, "Untitled prayer"),
      body: cleanString(text.body, ""),
      author: cleanString(text.author, "Amen"),
      tags: cleanStringArray(text.tags),
      timeOfDay: cleanString(shared.timeOfDay, "anytime"),
      readTimeMinutes: Number(shared.readTimeMinutes ?? 2),
      sortOrder: Number(shared.sortOrder ?? 0),
      isActive: true,
      backgroundImagePath: background.path || null,
      backgroundImageUrl: background.url || null,
      audioPath: audio.path || null,
      audioUrl: audio.url || null,
      createdAt: shared.createdAt ?? FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
  }

  batch.set(db.collection("catalog_admin_audit").doc(), {
    action: "publishPrayerCatalog",
    uid,
    locale,
    categoryCount: activeCategoryIds.size,
    prayerCount: sharedPrayersSnap.docs.filter((doc) => {
      const data = doc.data();
      return data.isActive !== false && activeCategoryIds.has(cleanString(data.categoryId, ""));
    }).length,
    createdAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  return {ok: true, errors: []};
});

export const reportIntention = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const intentionId = String(request.data?.intentionId ?? "");
  const reason = String(request.data?.reason ?? "Other Safety Concern").trim().slice(0, 80);

  if (!intentionId) {
    throw new HttpsError("invalid-argument", "intentionId is required.");
  }

  const intentionSnap = await db.collection("intentions").doc(intentionId).get();
  if (!intentionSnap.exists) {
    throw new HttpsError("not-found", "Prayer not found.");
  }
  if (intentionSnap.data()?.status !== "approved") {
    throw new HttpsError("failed-precondition", "Prayer is not available for reporting.");
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

export const sendSupportMessage = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const intentionId = String(request.data?.intentionId ?? "");
  const messageText = cleanSupportMessage(request.data?.messageText);
  const senderName = cleanSenderName(request.data?.senderName);

  if (!intentionId) {
    throw new HttpsError("invalid-argument", "intentionId is required.");
  }

  const intentionSnap = await db.collection("intentions").doc(intentionId).get();
  if (!intentionSnap.exists) {
    throw new HttpsError("not-found", "Prayer not found.");
  }

  const intention = intentionSnap.data() ?? {};
  if (intention.status !== "approved") {
    throw new HttpsError("failed-precondition", "Prayer is not available for support messages.");
  }

  const recipientUid = String(intention.authorUid ?? "");
  if (!recipientUid) {
    throw new HttpsError("failed-precondition", "Prayer has no recipient.");
  }
  if (recipientUid === uid) {
    throw new HttpsError("failed-precondition", "You cannot send a support message to yourself.");
  }

  const notificationRef = db.collection("notifications").doc();
  await notificationRef.set({
    recipientUid,
    senderUid: uid,
    senderName,
    senderAvatarUrl: null,
    intentionId,
    intentionText: String(intention.text ?? ""),
    category: String(intention.category ?? "general"),
    type: "supportMessage",
    messageText,
    createdAt: FieldValue.serverTimestamp(),
    isRead: false,
  });

  return {id: notificationRef.id, ok: true};
});

export const sayAmen = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const intentionId = String(request.data?.intentionId ?? "");
  if (!intentionId) {
    throw new HttpsError("invalid-argument", "intentionId is required.");
  }

  const intentionRef = db.collection("intentions").doc(intentionId);
  const eventRef = db.collection("amen_events").doc(`${intentionId}_${uid}`);

  await db.runTransaction(async (transaction) => {
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
    const authorUid = data.authorUid as string | undefined;
    transaction.set(eventRef, {
      intentionId,
      uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(intentionRef, {
      amenCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (authorUid && authorUid !== uid) {
      const notificationRef = db.collection("notifications").doc();
      transaction.set(notificationRef, {
        recipientUid: authorUid,
        senderUid: uid,
        senderName: "Believer in Christ",
        intentionId,
        intentionText: String(data.text ?? ""),
        category: String(data.category ?? "general"),
        type: "amen",
        messageText: null,
        createdAt: FieldValue.serverTimestamp(),
        isRead: false,
      });
    }
    return null;
  });

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

export const sendPrayerNotificationPush = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    const recipientUid = String(data?.recipientUid ?? "");
    if (!recipientUid) return;

    const type = String(data?.type ?? "amen");
    await notifyRecipient(recipientUid, type);
  },
);

async function notifyRecipient(recipientUid: string, type: string): Promise<void> {
  const tokens = await db
    .collection("device_tokens")
    .doc(recipientUid)
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
          body: notificationBody(locale, type),
        },
        data: {
          type: type === "supportMessage" ? "support_received" : "amen_received",
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
            .doc(recipientUid)
            .collection("tokens")
            .doc(docId)
            .delete();
        }
      }
    }),
  );
}

async function validateDraft(locale: string): Promise<{ok: boolean; errors: string[]}> {
  const [sharedCategoriesSnap, sharedPrayersSnap, localeCategoriesSnap, localePrayersSnap] =
    await Promise.all([
      db.collection("prayer_catalog_drafts/shared/categories").get(),
      db.collection("prayer_catalog_drafts/shared/prayers").get(),
      db.collection(`prayer_catalog_drafts/${locale}/categories`).get(),
      db.collection(`prayer_catalog_drafts/${locale}/prayers`).get(),
    ]);

  const errors: string[] = [];
  const localeCategories = new Map(localeCategoriesSnap.docs.map((doc) => [doc.id, doc.data()]));
  const localePrayers = new Map(localePrayersSnap.docs.map((doc) => [doc.id, doc.data()]));
  const activeCategoryIds = new Set<string>();

  for (const doc of sharedCategoriesSnap.docs) {
    const shared = doc.data();
    if (shared.isActive === false) continue;
    activeCategoryIds.add(doc.id);
    const text = localeCategories.get(doc.id) ?? {};
    if (!cleanString(text.title, "")) {
      errors.push(`${locale.toUpperCase()} catalog ${doc.id} is missing a title.`);
    }
    if (!Number.isFinite(Number(shared.sortOrder))) {
      errors.push(`Catalog ${doc.id} has an invalid sort order.`);
    }
  }

  if (activeCategoryIds.size === 0) {
    errors.push(`${locale.toUpperCase()} has no active catalogs.`);
  }

  let activePrayerCount = 0;
  for (const doc of sharedPrayersSnap.docs) {
    const shared = doc.data();
    if (shared.isActive === false) continue;
    const categoryId = cleanString(shared.categoryId, "");
    if (!activeCategoryIds.has(categoryId)) {
      errors.push(`Prayer ${doc.id} is assigned to an inactive or missing catalog.`);
      continue;
    }
    activePrayerCount += 1;
    const text = localePrayers.get(doc.id) ?? {};
    if (!cleanString(text.title, "")) {
      errors.push(`${locale.toUpperCase()} prayer ${doc.id} is missing a title.`);
    }
    if (!cleanString(text.body, "")) {
      errors.push(`${locale.toUpperCase()} prayer ${doc.id} is missing a body.`);
    }
    if (!Number.isFinite(Number(shared.sortOrder))) {
      errors.push(`Prayer ${doc.id} has an invalid sort order.`);
    }
    if (!Number.isFinite(Number(shared.readTimeMinutes))) {
      errors.push(`Prayer ${doc.id} has an invalid read time.`);
    }
  }

  if (activePrayerCount === 0) {
    errors.push(`${locale.toUpperCase()} has no active prayers.`);
  }

  return {ok: errors.length === 0, errors};
}

async function publishMedia(
  bucket: any,
  draftPath: string,
  destinationDir: string,
): Promise<{path: string; url: string}> {
  if (!draftPath) return {path: "", url: ""};
  if (draftPath.startsWith("prayer_catalog/published/")) {
    return {path: draftPath, url: storageUrl(bucket.name, draftPath)};
  }

  const source = bucket.file(draftPath);
  const [exists] = await source.exists();
  if (!exists) return {path: "", url: ""};

  const filename = basename(draftPath);
  const destinationPath = `${destinationDir}/${filename}`;
  await source.copy(bucket.file(destinationPath));
  return {path: destinationPath, url: storageUrl(bucket.name, destinationPath)};
}

function storageUrl(bucketName: string, path: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media`;
}

function basename(path: string): string {
  const parts = path.split("/").filter(Boolean);
  return parts[parts.length - 1] || "asset";
}

function cleanString(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function cleanStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean);
  }
  if (typeof value === "string") {
    return value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
  }
  return [];
}

function notificationBody(locale: string, type: string): string {
  if (type === "supportMessage") {
    if (locale.startsWith("es")) return "Alguien acaba de dejarte una palabra de aliento.";
    if (locale.startsWith("fr")) return "Quelqu’un vient de t’envoyer un mot d’encouragement.";
    return "Someone just left an encouraging prayer note for you.";
  }
  if (locale.startsWith("es")) return "Alguien acaba de elevar tu petición en oración.";
  if (locale.startsWith("fr")) return "Quelqu’un vient de porter ta demande dans la prière.";
  return "Someone just lifted your request up in prayer.";
}
