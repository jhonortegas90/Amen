import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/intention.dart';

abstract class IntentionsRepository {
  bool get isLive;
  Stream<List<Intention>> watchGlobalWall();
  Future<Intention> createIntention(
    String text,
    String locale, {
    PrayerCategory category,
    bool isAnonymous,
  });
  Future<void> sayAmen(String intentionId);
  Future<void> pinIntention(String intentionId);
}

class DemoIntentionsRepository implements IntentionsRepository {
  DemoIntentionsRepository({required this.currentAppUser}) {
    _intentions = [
      Intention(
        id: 'pinned-peace',
        authorUid: 'community',
        text: 'Praying for peace in our home.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        amenCount: 1847,
        isPinned: true,
        pinnedUntil: DateTime.now().add(const Duration(hours: 2)),
        locale: 'en',
        status: 'approved',
        category: PrayerCategory.peace,
      ),
      Intention(
        id: 'healing',
        authorUid: 'anon-1',
        text: 'Praying for healing and strength for a loved one.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        amenCount: 314,
        isPinned: false,
        locale: 'en',
        status: 'approved',
        category: PrayerCategory.healing,
      ),
      Intention(
        id: 'hurting',
        authorUid: 'anon-2',
        text: 'Praying for those who are hurting right now.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        amenCount: 228,
        isPinned: false,
        locale: 'en',
        status: 'approved',
        category: PrayerCategory.grief,
      ),
      Intention(
        id: 'wisdom',
        authorUid: currentUid,
        text: 'Praying for wisdom and guidance today.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        amenCount: 191,
        isPinned: false,
        locale: 'en',
        status: 'approved',
        category: PrayerCategory.guidance,
      ),
      Intention(
        id: 'unity',
        authorUid: 'anon-3',
        text: 'Praying for unity and kindness in the world.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        amenCount: 166,
        isPinned: false,
        locale: 'en',
        status: 'approved',
        category: PrayerCategory.strength,
      ),
    ];
    _emit();
  }

  final AppUser? currentAppUser;
  String get currentUid => currentAppUser?.uid ?? 'guest';
  final _controller = StreamController<List<Intention>>.broadcast();
  final _amened = <String>{};
  late List<Intention> _intentions;

  @override
  bool get isLive => false;

  @override
  Stream<List<Intention>> watchGlobalWall() async* {
    yield _sortedIntentions();
    yield* _controller.stream;
  }

  @override
  Future<Intention> createIntention(
    String text,
    String locale, {
    PrayerCategory category = PrayerCategory.general,
    bool isAnonymous = true,
  }) async {
    final intention = Intention(
      id: const Uuid().v4(),
      authorUid: currentUid,
      text: text.trim(),
      createdAt: DateTime.now(),
      amenCount: 0,
      isPinned: false,
      locale: locale,
      status: 'approved',
      category: category,
      isAnonymous: isAnonymous,
      authorName: isAnonymous
          ? null
          : (currentAppUser?.displayName ?? 'Pilgrim'),
      authorAvatarUrl: isAnonymous ? null : currentAppUser?.photoUrl,
    );
    _intentions = [intention, ..._intentions];
    _emit();
    return intention;
  }

  @override
  Future<void> sayAmen(String intentionId) async {
    if (!_amened.add(intentionId)) return;
    _intentions = [
      for (final intention in _intentions)
        if (intention.id == intentionId)
          intention.copyWith(amenCount: intention.amenCount + 1)
        else
          intention,
    ];
    _emit();
  }

  @override
  Future<void> pinIntention(String intentionId) async {
    _intentions = [
      for (final intention in _intentions)
        if (intention.id == intentionId)
          intention.copyWith(
            isPinned: true,
            pinnedUntil: DateTime.now().add(const Duration(hours: 2)),
          )
        else
          intention,
    ];
    _emit();
  }

  void _emit() {
    _controller.add(_sortedIntentions());
  }

  List<Intention> _sortedIntentions() {
    return [..._intentions]..sort((a, b) {
      final pinnedCompare = (b.isCurrentlyPinned ? 1 : 0).compareTo(
        a.isCurrentlyPinned ? 1 : 0,
      );
      if (pinnedCompare != 0) return pinnedCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}

class FirebaseIntentionsRepository implements IntentionsRepository {
  FirebaseIntentionsRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  bool get isLive => true;

  @override
  Stream<List<Intention>> watchGlobalWall() {
    return _firestore
        .collection('intentions')
        .where('status', isEqualTo: 'approved')
        .orderBy('isPinned', descending: true)
        .orderBy('pinnedUntil', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Intention.fromFirestore).toList());
  }

  @override
  Future<Intention> createIntention(
    String text,
    String locale, {
    PrayerCategory category = PrayerCategory.general,
    bool isAnonymous = true,
  }) async {
    final result = await _functions.httpsCallable('createIntention').call({
      'text': text.trim(),
      'locale': locale,
      'category': category.name,
      'isAnonymous': isAnonymous,
      'schemaVersion': 1,
    });
    final id = (result.data as Map?)?['id'] as String?;
    if (id == null) {
      throw StateError('createIntention did not return an id.');
    }
    final snapshot = await _firestore.collection('intentions').doc(id).get();
    return Intention.fromFirestore(snapshot);
  }

  @override
  Future<void> sayAmen(String intentionId) async {
    await _functions.httpsCallable('sayAmen').call({
      'intentionId': intentionId,
      'schemaVersion': 1,
    });
  }

  @override
  Future<void> pinIntention(String intentionId) async {
    await _functions.httpsCallable('pinIntention').call({
      'intentionId': intentionId,
      'schemaVersion': 1,
    });
  }
}

final intentionsRepositoryProvider = Provider<IntentionsRepository>((ref) {
  final bootstrap = ref.watch(firebaseBootstrapProvider);
  if (bootstrap.isLive) return FirebaseIntentionsRepository();

  final appUser = ref.watch(authRepositoryProvider).currentUser;
  return DemoIntentionsRepository(currentAppUser: appUser);
});
