import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../../auth/data/auth_repository.dart';
import '../../intentions/domain/intention.dart';
import '../domain/prayer_notification.dart';

abstract class NotificationsRepository {
  bool get isLive;
  Stream<List<PrayerNotification>> watchNotifications(String recipientUid);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String recipientUid);
  Future<void> addNotification(PrayerNotification notification);
  Future<void> sendSupportMessage({
    required String intentionId,
    required String intentionText,
    required PrayerCategory category,
    required String recipientUid,
    required String messageText,
    String? senderName,
    String? senderUid,
  });
  Future<void> sendAmenNotification({
    required String intentionId,
    required String intentionText,
    required PrayerCategory category,
    required String recipientUid,
    String? senderName,
    String? senderUid,
  });
}

class DemoNotificationsRepository implements NotificationsRepository {
  DemoNotificationsRepository({required this.currentUid}) {
    _notifications = [
      PrayerNotification(
        id: 'notif-1',
        recipientUid: currentUid,
        senderUid: 'pastor-david-uid',
        senderName: 'Pastor David',
        intentionId: 'wisdom',
        intentionText: 'Praying for wisdom and guidance today.',
        category: PrayerCategory.guidance,
        type: NotificationType.supportMessage,
        messageText:
            'Standing with you in prayer! May the Lord grant you clarity, wisdom, and peace beyond understanding today.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      PrayerNotification(
        id: 'notif-2',
        recipientUid: currentUid,
        senderUid: 'sarah-m-uid',
        senderName: 'Sarah M.',
        intentionId: 'wisdom',
        intentionText: 'Praying for wisdom and guidance today.',
        category: PrayerCategory.guidance,
        type: NotificationType.amen,
        createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
        isRead: false,
      ),
      PrayerNotification(
        id: 'notif-3',
        recipientUid: currentUid,
        senderUid: 'sister-grace-uid',
        senderName: 'Sister Grace',
        intentionId: 'pinned-peace',
        intentionText: 'Praying for peace in our home.',
        category: PrayerCategory.peace,
        type: NotificationType.supportMessage,
        messageText:
            'May God’s peace which passes all understanding guard your heart and your family’s home today.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      PrayerNotification(
        id: 'notif-4',
        recipientUid: currentUid,
        senderUid: 'brother-michael-uid',
        senderName: 'Brother Michael',
        intentionId: 'pinned-peace',
        intentionText: 'Praying for peace in our home.',
        category: PrayerCategory.peace,
        type: NotificationType.amen,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      PrayerNotification(
        id: 'notif-5',
        recipientUid: currentUid,
        senderUid: 'community-uid',
        senderName: 'Believer in Christ',
        intentionId: 'wisdom',
        intentionText: 'Praying for wisdom and guidance today.',
        category: PrayerCategory.guidance,
        type: NotificationType.amen,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
    _emit();
  }

  final String currentUid;
  final _controller = StreamController<List<PrayerNotification>>.broadcast();
  late List<PrayerNotification> _notifications;

  @override
  bool get isLive => false;

  void _emit() {
    _controller.add(List.unmodifiable(_sortedNotifications()));
  }

  List<PrayerNotification> _sortedNotifications() {
    final list = [..._notifications];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<PrayerNotification>> watchNotifications(
    String recipientUid,
  ) async* {
    yield _sortedNotifications();
    yield* _controller.stream;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    _notifications = [
      for (final n in _notifications)
        if (n.id == notificationId) n.copyWith(isRead: true) else n,
    ];
    _emit();
  }

  @override
  Future<void> markAllAsRead(String recipientUid) async {
    _notifications = [for (final n in _notifications) n.copyWith(isRead: true)];
    _emit();
  }

  @override
  Future<void> addNotification(PrayerNotification notification) async {
    _notifications = [notification, ..._notifications];
    _emit();
  }

  @override
  Future<void> sendSupportMessage({
    required String intentionId,
    required String intentionText,
    required PrayerCategory category,
    required String recipientUid,
    required String messageText,
    String? senderName,
    String? senderUid,
  }) async {
    final notif = PrayerNotification(
      id: const Uuid().v4(),
      recipientUid: recipientUid,
      senderUid: senderUid ?? currentUid,
      senderName: senderName ?? 'A Brother/Sister in Faith',
      intentionId: intentionId,
      intentionText: intentionText,
      category: category,
      type: NotificationType.supportMessage,
      messageText: messageText,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await addNotification(notif);
  }

  @override
  Future<void> sendAmenNotification({
    required String intentionId,
    required String intentionText,
    required PrayerCategory category,
    required String recipientUid,
    String? senderName,
    String? senderUid,
  }) async {
    final notif = PrayerNotification(
      id: const Uuid().v4(),
      recipientUid: recipientUid,
      senderUid: senderUid ?? currentUid,
      senderName: senderName ?? 'Believer in Christ',
      intentionId: intentionId,
      intentionText: intentionText,
      category: category,
      type: NotificationType.amen,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await addNotification(notif);
  }
}

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository({
    required this.firestore,
    FirebaseFunctions? functions,
    required this.currentUid,
  }) : functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  final String currentUid;

  @override
  bool get isLive => true;

  @override
  Stream<List<PrayerNotification>> watchNotifications(String recipientUid) {
    if (recipientUid == 'guest') {
      return Stream.value(<PrayerNotification>[]);
    }

    return firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: recipientUid)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map(PrayerNotification.fromFirestore)
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        })
        .handleError((error) {
          debugPrint('watchNotifications error: $error');
          throw error;
        });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  @override
  Future<void> markAllAsRead(String recipientUid) async {
    final query = await firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: recipientUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> addNotification(PrayerNotification notification) async {
    throw UnsupportedError(
      'Notifications must be created by server functions.',
    );
  }

  @override
  Future<void> sendSupportMessage({
    required String intentionId,
    required String intentionText,
    required PrayerCategory category,
    required String recipientUid,
    required String messageText,
    String? senderName,
    String? senderUid,
  }) async {
    await functions.httpsCallable('sendSupportMessage').call({
      'intentionId': intentionId,
      'messageText': messageText,
      'senderName': senderName,
      'schemaVersion': 1,
    });
  }

  @override
  Future<void> sendAmenNotification({
    required String intentionId,
    required String intentionText,
    required PrayerCategory category,
    required String recipientUid,
    String? senderName,
    String? senderUid,
  }) async {
    throw UnsupportedError('Amen notifications are created by sayAmen.');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final bootstrap = ref.watch(firebaseBootstrapProvider);
  final user = ref.watch(authStateProvider).value;
  final currentUid = user?.uid ?? 'guest';

  if (!bootstrap.isLive) {
    return DemoNotificationsRepository(currentUid: currentUid);
  }

  return FirestoreNotificationsRepository(
    firestore: FirebaseFirestore.instance,
    currentUid: currentUid,
  );
});

final userNotificationsProvider = StreamProvider<List<PrayerNotification>>((
  ref,
) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  final currentUid = user?.uid ?? 'guest';
  return repo.watchNotifications(currentUid);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
