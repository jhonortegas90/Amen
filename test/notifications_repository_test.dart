import 'package:flutter_test/flutter_test.dart';
import 'package:amen/src/features/intentions/domain/intention.dart';
import 'package:amen/src/features/notifications/data/notifications_repository.dart';
import 'package:amen/src/features/notifications/domain/prayer_notification.dart';

void main() {
  group('DemoNotificationsRepository', () {
    late DemoNotificationsRepository repository;
    const testUid = 'user-123';

    setUp(() {
      repository = DemoNotificationsRepository(currentUid: testUid);
    });

    test('initial notifications load and sort descending by date', () async {
      final stream = repository.watchNotifications(testUid);
      final notifications = await stream.first;

      expect(notifications, isNotEmpty);
      expect(notifications.length, equals(5));

      // Ensure sorted by createdAt descending
      for (var i = 0; i < notifications.length - 1; i++) {
        expect(
          notifications[i].createdAt.isAfter(notifications[i + 1].createdAt) ||
              notifications[i].createdAt.isAtSameMomentAs(notifications[i + 1].createdAt),
          isTrue,
        );
      }
    });

    test('markAsRead updates isRead state for specified notification', () async {
      final initialNotifications = await repository.watchNotifications(testUid).first;
      final unreadItem = initialNotifications.firstWhere((n) => !n.isRead);

      await repository.markAsRead(unreadItem.id);

      final updatedNotifications = await repository.watchNotifications(testUid).first;
      final updatedItem = updatedNotifications.firstWhere((n) => n.id == unreadItem.id);

      expect(updatedItem.isRead, isTrue);
    });

    test('markAllAsRead marks all notifications as read', () async {
      await repository.markAllAsRead(testUid);

      final notifications = await repository.watchNotifications(testUid).first;
      final unreadCount = notifications.where((n) => !n.isRead).length;

      expect(unreadCount, equals(0));
    });

    test('sendSupportMessage adds a new supportMessage notification', () async {
      await repository.sendSupportMessage(
        intentionId: 'healing-1',
        intentionText: 'Praying for quick recovery',
        category: PrayerCategory.healing,
        recipientUid: testUid,
        messageText: 'May God restore your health fully!',
        senderName: 'John Doe',
      );

      final notifications = await repository.watchNotifications(testUid).first;
      expect(notifications.length, equals(6));

      final newest = notifications.first;
      expect(newest.type, equals(NotificationType.supportMessage));
      expect(newest.senderName, equals('John Doe'));
      expect(newest.messageText, equals('May God restore your health fully!'));
      expect(newest.isRead, isFalse);
    });

    test('sendAmenNotification adds a new amen notification', () async {
      await repository.sendAmenNotification(
        intentionId: 'healing-1',
        intentionText: 'Praying for quick recovery',
        category: PrayerCategory.healing,
        recipientUid: testUid,
        senderName: 'Mary S.',
      );

      final notifications = await repository.watchNotifications(testUid).first;
      final newest = notifications.first;

      expect(newest.type, equals(NotificationType.amen));
      expect(newest.senderName, equals('Mary S.'));
      expect(newest.isRead, isFalse);
    });
  });
}
