import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../domain/prayer_reflection.dart';

const supportedCatalogLocales = ['en', 'es', 'fr'];

String normalizeCatalogLocale(String locale) {
  final normalized = locale.toLowerCase().split(RegExp('[-_]')).first;
  return supportedCatalogLocales.contains(normalized) ? normalized : 'en';
}

abstract class LibraryRepository {
  Stream<List<PrayerCatalogCategory>> watchCategories(String locale);
  Stream<List<PrayerReflection>> watchItems({
    required String locale,
    String? categoryId,
    String? searchQuery,
  });
}

class DemoLibraryRepository implements LibraryRepository {
  DemoLibraryRepository();

  static final List<PrayerCatalogCategory> _seedCategories = [
    const PrayerCatalogCategory(
      id: 'morning',
      title: 'Morning',
      description: 'Begin the day with wisdom, light, and surrender.',
      sortOrder: 10,
      isActive: true,
    ),
    const PrayerCatalogCategory(
      id: 'anxiety-peace',
      title: 'Anxiety & Peace',
      description: 'Quiet prayers for calm, trust, and breath.',
      sortOrder: 20,
      isActive: true,
    ),
    const PrayerCatalogCategory(
      id: 'healing',
      title: 'Healing',
      description: 'Prayers for physical and spiritual restoration.',
      sortOrder: 30,
      isActive: true,
    ),
    const PrayerCatalogCategory(
      id: 'evening',
      title: 'Evening',
      description: 'Close the day in gratitude, forgiveness, and rest.',
      sortOrder: 40,
      isActive: true,
    ),
    const PrayerCatalogCategory(
      id: 'strength',
      title: 'Strength',
      description: 'Courage and perseverance in seasons of trial.',
      sortOrder: 50,
      isActive: true,
    ),
  ];

  static final List<PrayerReflection> _seedItems = [
    PrayerReflection(
      id: 'p1',
      title: 'Morning Prayer for Wisdom & Light',
      category: 'Morning',
      categoryId: 'morning',
      categoryDescription: 'Begin the day with wisdom, light, and surrender.',
      timeOfDay: TimeOfDayTag.morning,
      tags: ['wisdom', 'morning', 'guidance', 'peace'],
      author: 'Ancient Liturgy',
      readTimeMinutes: 2,
      sortOrder: 10,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      body: '''
Lord, as the sun rises today, fill my heart with Your divine light.
Grant me wisdom in every decision, patience with every encounter, and grace in all my words.
May I walk through this day with calm assurance that You go before me.
Amen.
''',
    ),
    PrayerReflection(
      id: 'p2',
      title: 'Quiet Peace in Anxiety & Turbulence',
      category: 'Anxiety & Peace',
      categoryId: 'anxiety-peace',
      categoryDescription: 'Quiet prayers for calm, trust, and breath.',
      timeOfDay: TimeOfDayTag.anytime,
      tags: ['anxiety', 'peace', 'calm', 'trust'],
      author: 'Contemplative Prayer',
      readTimeMinutes: 3,
      sortOrder: 20,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      body: '''
Father, when my thoughts run wild and my chest feels heavy, I cast every care upon You.
You are the anchor in my storm. Still my mind, soften my breath, and remind me that You hold all my tomorrows.
I release control and rest in Your quiet presence.
Amen.
''',
    ),
    PrayerReflection(
      id: 'p3',
      title: 'Prayer for Physical & Spiritual Healing',
      category: 'Healing',
      categoryId: 'healing',
      categoryDescription: 'Prayers for physical and spiritual restoration.',
      timeOfDay: TimeOfDayTag.anytime,
      tags: ['healing', 'health', 'restoration', 'faith'],
      author: 'St. Francis Tradition',
      readTimeMinutes: 2,
      sortOrder: 30,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      body: '''
Divine Healer, touch every place of pain, weakness, or weariness within me.
Breathe life into tired bones and renewal into wounded spirits.
May Your restorative power flow through my body and mind today.
Amen.
''',
    ),
    PrayerReflection(
      id: 'p4',
      title: 'Evening Devotional: Surrendering the Day',
      category: 'Evening',
      categoryId: 'evening',
      categoryDescription: 'Close the day in gratitude, forgiveness, and rest.',
      timeOfDay: TimeOfDayTag.evening,
      tags: ['evening', 'rest', 'sleep', 'surrender'],
      author: 'Benedictine Wisdom',
      readTimeMinutes: 3,
      sortOrder: 40,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      body: '''
Heavenly Father, as night falls, I release the burdens and incomplete tasks of today into Your hands.
Forgive my shortcomings, receive my gratitude, and guard my sleep with Your holy presence.
I sleep in safety because You never slumber.
Amen.
''',
    ),
    PrayerReflection(
      id: 'p5',
      title: 'Strength in Trials & Times of Trouble',
      category: 'Strength',
      categoryId: 'strength',
      categoryDescription: 'Courage and perseverance in seasons of trial.',
      timeOfDay: TimeOfDayTag.anytime,
      tags: ['strength', 'courage', 'perseverance', 'hope'],
      author: 'Desert Fathers',
      readTimeMinutes: 4,
      sortOrder: 50,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      body: '''
Lord God, You are my fortress when walls crumble around me.
Grant me fortitude to stand firm, courage to face difficulty, and faith to see beyond present hardships.
For when I am weak, Your strength is made perfect.
Amen.
''',
    ),
  ];

  @override
  Stream<List<PrayerCatalogCategory>> watchCategories(String locale) {
    return Stream.value(_seedCategories);
  }

  @override
  Stream<List<PrayerReflection>> watchItems({
    required String locale,
    String? categoryId,
    String? searchQuery,
  }) {
    return Stream.value(
      _filterItems(
        _seedItems,
        categoryId: categoryId,
        searchQuery: searchQuery,
      ),
    );
  }
}

class FirebaseLibraryRepository implements LibraryRepository {
  FirebaseLibraryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _categories(String locale) {
    return _firestore
        .collection('prayer_catalog_published')
        .doc(normalizeCatalogLocale(locale))
        .collection('categories');
  }

  CollectionReference<Map<String, dynamic>> _prayers(String locale) {
    return _firestore
        .collection('prayer_catalog_published')
        .doc(normalizeCatalogLocale(locale))
        .collection('prayers');
  }

  @override
  Stream<List<PrayerCatalogCategory>> watchCategories(String locale) {
    return _categories(locale).orderBy('sortOrder').snapshots().map((snapshot) {
      return snapshot.docs
          .map(PrayerCatalogCategory.fromFirestore)
          .where((category) => category.isActive)
          .toList(growable: false);
    });
  }

  @override
  Stream<List<PrayerReflection>> watchItems({
    required String locale,
    String? categoryId,
    String? searchQuery,
  }) {
    return _prayers(locale).orderBy('sortOrder').snapshots().map((snapshot) {
      return _filterItems(
        snapshot.docs.map(PrayerReflection.fromFirestore),
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
    });
  }
}

List<PrayerReflection> _filterItems(
  Iterable<PrayerReflection> items, {
  String? categoryId,
  String? searchQuery,
}) {
  return items
      .where((item) {
        if (!item.isActive) return false;
        if (categoryId != null &&
            categoryId != 'all' &&
            item.categoryId != categoryId) {
          return false;
        }
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final query = searchQuery.toLowerCase().trim();
          final matchTitle = item.title.toLowerCase().contains(query);
          final matchBody = item.body.toLowerCase().contains(query);
          final matchTags = item.tags.any(
            (tag) => tag.toLowerCase().contains(query),
          );
          final matchCategory = item.category.toLowerCase().contains(query);
          return matchTitle || matchBody || matchTags || matchCategory;
        }
        return true;
      })
      .toList(growable: false);
}

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final bootstrap = ref.watch(firebaseBootstrapProvider);
  if (bootstrap.isLive) return FirebaseLibraryRepository();
  return DemoLibraryRepository();
});

final publishedCatalogCategoriesProvider =
    StreamProvider.family<List<PrayerCatalogCategory>, String>((ref, locale) {
      return ref.watch(libraryRepositoryProvider).watchCategories(locale);
    });

final publishedPrayerItemsProvider =
    StreamProvider.family<
      List<PrayerReflection>,
      ({String locale, String? categoryId, String? searchQuery})
    >((ref, query) {
      return ref
          .watch(libraryRepositoryProvider)
          .watchItems(
            locale: query.locale,
            categoryId: query.categoryId,
            searchQuery: query.searchQuery,
          );
    });
