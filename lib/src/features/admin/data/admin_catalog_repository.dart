import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/data/library_repository.dart';
import '../../library/domain/prayer_reflection.dart';

const initialCatalogAdminEmail = 'j.a.t.creativestudios@gmail.com';

enum CatalogMediaTarget { categoryBackground, prayerBackground, prayerAudio }

class CatalogAdminStatus {
  const CatalogAdminStatus({
    required this.isSignedIn,
    required this.isAdmin,
    this.email,
    this.message,
  });

  final bool isSignedIn;
  final bool isAdmin;
  final String? email;
  final String? message;
}

class CatalogMediaUpload {
  const CatalogMediaUpload({
    required this.url,
    required this.path,
    required this.contentType,
    required this.size,
  });

  final String url;
  final String path;
  final String contentType;
  final int size;
}

class AdminCatalogRepository {
  AdminCatalogRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _sharedCategories => _firestore
      .collection('prayer_catalog_drafts')
      .doc('shared')
      .collection('categories');

  CollectionReference<Map<String, dynamic>> get _sharedPrayers => _firestore
      .collection('prayer_catalog_drafts')
      .doc('shared')
      .collection('prayers');

  CollectionReference<Map<String, dynamic>> _localeCategories(String locale) =>
      _firestore
          .collection('prayer_catalog_drafts')
          .doc(normalizeCatalogLocale(locale))
          .collection('categories');

  CollectionReference<Map<String, dynamic>> _localePrayers(String locale) =>
      _firestore
          .collection('prayer_catalog_drafts')
          .doc(normalizeCatalogLocale(locale))
          .collection('prayers');

  Future<CatalogAdminStatus> checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return const CatalogAdminStatus(isSignedIn: false, isAdmin: false);
    }

    final token = await user.getIdTokenResult(true);
    final hasClaim = token.claims?['catalogAdmin'] == true;
    final email = user.email?.toLowerCase().trim();
    if (hasClaim && email == initialCatalogAdminEmail) {
      return CatalogAdminStatus(
        isSignedIn: true,
        isAdmin: true,
        email: user.email,
      );
    }

    if (email == initialCatalogAdminEmail) {
      try {
        await _functions.httpsCallable('bootstrapCatalogAdmin').call();
        final refreshed = await user.getIdTokenResult(true);
        final isAdmin = refreshed.claims?['catalogAdmin'] == true;
        return CatalogAdminStatus(
          isSignedIn: true,
          isAdmin: isAdmin,
          email: user.email,
          message: isAdmin
              ? 'Admin access enabled. Refreshing your session completed.'
              : 'Admin bootstrap finished, but the token did not include the admin claim.',
        );
      } catch (error) {
        return CatalogAdminStatus(
          isSignedIn: true,
          isAdmin: false,
          email: user.email,
          message:
              'Signed in, but admin bootstrap is not available yet: $error',
        );
      }
    }

    return CatalogAdminStatus(
      isSignedIn: true,
      isAdmin: false,
      email: user.email,
      message: 'This account does not have catalog admin access.',
    );
  }

  Stream<List<PrayerCatalogCategory>> watchDraftCategories(String locale) {
    final controller = StreamController<List<PrayerCatalogCategory>>();
    var sharedDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var localeDocs = <String, Map<String, dynamic>>{};

    void emit() {
      final categories =
          sharedDocs
              .map((doc) {
                final shared = doc.data();
                final localized =
                    localeDocs[doc.id] ?? const <String, dynamic>{};
                return PrayerCatalogCategory(
                  id: doc.id,
                  title: stringValue(
                    localized['title'],
                    fallback: 'Untitled catalog',
                  ),
                  description: stringValue(localized['description']),
                  sortOrder: intValue(shared['sortOrder'], fallback: 0),
                  isActive: boolValue(shared['isActive'], fallback: true),
                  backgroundImageUrl: nullableString(
                    shared['backgroundImageUrl'],
                  ),
                  backgroundImagePath: nullableString(
                    shared['backgroundImagePath'],
                  ),
                  createdAt: dateValue(shared['createdAt']),
                  updatedAt:
                      dateValue(shared['updatedAt']) ??
                      dateValue(localized['updatedAt']),
                );
              })
              .toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      controller.add(categories);
    }

    final sharedSubscription = _sharedCategories.snapshots().listen((snapshot) {
      sharedDocs = snapshot.docs;
      emit();
    }, onError: controller.addError);

    final localeSubscription = _localeCategories(locale).snapshots().listen((
      snapshot,
    ) {
      localeDocs = {for (final doc in snapshot.docs) doc.id: doc.data()};
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await sharedSubscription.cancel();
      await localeSubscription.cancel();
    };
    return controller.stream;
  }

  Stream<List<PrayerReflection>> watchDraftPrayers(String locale) {
    final controller = StreamController<List<PrayerReflection>>();
    var sharedDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var prayerTextDocs = <String, Map<String, dynamic>>{};
    var categoryTextDocs = <String, Map<String, dynamic>>{};

    void emit() {
      final prayers =
          sharedDocs
              .map((doc) {
                final shared = doc.data();
                final localized =
                    prayerTextDocs[doc.id] ?? const <String, dynamic>{};
                final categoryId = stringValue(shared['categoryId']);
                final localizedCategory =
                    categoryTextDocs[categoryId] ?? const <String, dynamic>{};
                return PrayerReflection(
                  id: doc.id,
                  title: stringValue(
                    localized['title'],
                    fallback: 'Untitled prayer',
                  ),
                  body: stringValue(localized['body']),
                  category: stringValue(
                    localizedCategory['title'],
                    fallback: 'Prayer',
                  ),
                  categoryId: categoryId,
                  categoryDescription: stringValue(
                    localizedCategory['description'],
                  ),
                  tags: stringListValue(localized['tags']),
                  timeOfDay: TimeOfDayTag.fromName(
                    nullableString(shared['timeOfDay']),
                  ),
                  author: stringValue(localized['author'], fallback: 'Amen'),
                  readTimeMinutes: intValue(
                    shared['readTimeMinutes'],
                    fallback: 2,
                  ),
                  sortOrder: intValue(shared['sortOrder'], fallback: 0),
                  isActive: boolValue(shared['isActive'], fallback: true),
                  createdAt: dateValue(shared['createdAt']) ?? DateTime.now(),
                  updatedAt:
                      dateValue(shared['updatedAt']) ??
                      dateValue(localized['updatedAt']),
                  backgroundImageUrl: nullableString(
                    shared['backgroundImageUrl'],
                  ),
                  backgroundImagePath: nullableString(
                    shared['backgroundImagePath'],
                  ),
                  audioUrl: nullableString(shared['audioUrl']),
                  audioPath: nullableString(shared['audioPath']),
                );
              })
              .toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      controller.add(prayers);
    }

    final sharedSubscription = _sharedPrayers.snapshots().listen((snapshot) {
      sharedDocs = snapshot.docs;
      emit();
    }, onError: controller.addError);

    final textSubscription = _localePrayers(locale).snapshots().listen((
      snapshot,
    ) {
      prayerTextDocs = {for (final doc in snapshot.docs) doc.id: doc.data()};
      emit();
    }, onError: controller.addError);

    final categorySubscription = _localeCategories(locale).snapshots().listen((
      snapshot,
    ) {
      categoryTextDocs = {for (final doc in snapshot.docs) doc.id: doc.data()};
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await sharedSubscription.cancel();
      await textSubscription.cancel();
      await categorySubscription.cancel();
    };
    return controller.stream;
  }

  Future<String> createCategory(String locale) async {
    final doc = _sharedCategories.doc();
    final sortOrder = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.set(doc, {
      'id': doc.id,
      'sortOrder': sortOrder,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final code in supportedCatalogLocales) {
      batch.set(_localeCategories(code).doc(doc.id), {
        'title': code == normalizeCatalogLocale(locale)
            ? 'Untitled catalog'
            : '',
        'description': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return doc.id;
  }

  Future<String> createPrayer(String locale, String categoryId) async {
    final doc = _sharedPrayers.doc();
    final sortOrder = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.set(doc, {
      'id': doc.id,
      'categoryId': categoryId,
      'sortOrder': sortOrder,
      'isActive': true,
      'timeOfDay': TimeOfDayTag.anytime.name,
      'readTimeMinutes': 2,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final code in supportedCatalogLocales) {
      batch.set(_localePrayers(code).doc(doc.id), {
        'title': code == normalizeCatalogLocale(locale)
            ? 'Untitled prayer'
            : '',
        'body': '',
        'author': '',
        'tags': <String>[],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return doc.id;
  }

  Future<void> saveCategoryShared(PrayerCatalogCategory category) {
    return _sharedCategories.doc(category.id).set({
      'id': category.id,
      'sortOrder': category.sortOrder,
      'isActive': category.isActive,
      'backgroundImageUrl': category.backgroundImageUrl,
      'backgroundImagePath': category.backgroundImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveCategoryText({
    required String locale,
    required String categoryId,
    required String title,
    required String description,
  }) {
    return _localeCategories(locale).doc(categoryId).set({
      'title': title.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> savePrayerShared(PrayerReflection prayer) {
    return _sharedPrayers.doc(prayer.id).set({
      'id': prayer.id,
      'categoryId': prayer.categoryId,
      'sortOrder': prayer.sortOrder,
      'isActive': prayer.isActive,
      'timeOfDay': prayer.timeOfDay.name,
      'readTimeMinutes': prayer.readTimeMinutes,
      'backgroundImageUrl': prayer.backgroundImageUrl,
      'backgroundImagePath': prayer.backgroundImagePath,
      'audioUrl': prayer.audioUrl,
      'audioPath': prayer.audioPath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> savePrayerText({
    required String locale,
    required String prayerId,
    required String title,
    required String body,
    required String author,
    required List<String> tags,
  }) {
    return _localePrayers(locale).doc(prayerId).set({
      'title': title.trim(),
      'body': body.trim(),
      'author': author.trim(),
      'tags': tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<CatalogMediaUpload> pickAndUploadMedia({
    required CatalogMediaTarget target,
    required String ownerId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: target == CatalogMediaTarget.prayerAudio
          ? FileType.audio
          : FileType.image,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      throw StateError('No file selected.');
    }
    return uploadMedia(
      target: target,
      ownerId: ownerId,
      filename: file.name,
      bytes: bytes,
      contentType: _contentTypeFor(file),
    );
  }

  Future<CatalogMediaUpload> uploadMedia({
    required CatalogMediaTarget target,
    required String ownerId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safeName = _safeFilename(filename);
    final path = _draftStoragePath(target, ownerId, safeName);
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'unknown',
          'target': target.name,
          'ownerId': ownerId,
        },
      ),
    );
    final url = await ref.getDownloadURL();
    final upload = CatalogMediaUpload(
      url: url,
      path: path,
      contentType: contentType,
      size: bytes.lengthInBytes,
    );

    switch (target) {
      case CatalogMediaTarget.categoryBackground:
        await _sharedCategories.doc(ownerId).set({
          'backgroundImageUrl': upload.url,
          'backgroundImagePath': upload.path,
          'backgroundImageContentType': upload.contentType,
          'backgroundImageSize': upload.size,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      case CatalogMediaTarget.prayerBackground:
        await _sharedPrayers.doc(ownerId).set({
          'backgroundImageUrl': upload.url,
          'backgroundImagePath': upload.path,
          'backgroundImageContentType': upload.contentType,
          'backgroundImageSize': upload.size,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      case CatalogMediaTarget.prayerAudio:
        await _sharedPrayers.doc(ownerId).set({
          'audioUrl': upload.url,
          'audioPath': upload.path,
          'audioContentType': upload.contentType,
          'audioSize': upload.size,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    }

    return upload;
  }

  Future<List<String>> validatePrayerCatalog(String locale) async {
    final result = await _functions
        .httpsCallable('validatePrayerCatalogDraft')
        .call({'locale': normalizeCatalogLocale(locale)});
    final data = result.data;
    if (data is Map && data['errors'] is Iterable) {
      return (data['errors'] as Iterable).map((item) => '$item').toList();
    }
    return const [];
  }

  Future<List<String>> publishPrayerCatalog(String locale) async {
    final result = await _functions.httpsCallable('publishPrayerCatalog').call({
      'locale': normalizeCatalogLocale(locale),
    });
    final data = result.data;
    if (data is Map && data['errors'] is Iterable) {
      return (data['errors'] as Iterable).map((item) => '$item').toList();
    }
    return const [];
  }

  String _draftStoragePath(
    CatalogMediaTarget target,
    String ownerId,
    String filename,
  ) {
    return switch (target) {
      CatalogMediaTarget.categoryBackground =>
        'prayer_catalog/drafts/categories/$ownerId/background/$filename',
      CatalogMediaTarget.prayerBackground =>
        'prayer_catalog/drafts/prayers/$ownerId/background/$filename',
      CatalogMediaTarget.prayerAudio =>
        'prayer_catalog/drafts/prayers/$ownerId/audio/$filename',
    };
  }

  String _safeFilename(String filename) {
    final parts = filename.split('.');
    final extension = parts.length > 1 ? '.${parts.last.toLowerCase()}' : '';
    final stem = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join('.')
        : filename;
    final safeStem = stem
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeStem.isEmpty ? 'upload' : safeStem}-$timestamp$extension';
  }

  String _contentTypeFor(PlatformFile file) {
    final ext = (file.extension ?? file.name.split('.').last).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      _ => 'application/octet-stream',
    };
  }
}

final adminCatalogRepositoryProvider = Provider<AdminCatalogRepository>((ref) {
  return AdminCatalogRepository();
});

final adminStatusProvider = FutureProvider<CatalogAdminStatus>((ref) {
  return ref.watch(adminCatalogRepositoryProvider).checkAdminStatus();
});

final draftCategoriesProvider =
    StreamProvider.family<List<PrayerCatalogCategory>, String>((ref, locale) {
      return ref
          .watch(adminCatalogRepositoryProvider)
          .watchDraftCategories(locale);
    });

final draftPrayersProvider =
    StreamProvider.family<List<PrayerReflection>, String>((ref, locale) {
      return ref
          .watch(adminCatalogRepositoryProvider)
          .watchDraftPrayers(locale);
    });
