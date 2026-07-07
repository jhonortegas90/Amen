import 'package:cloud_firestore/cloud_firestore.dart';
import '../../intentions/domain/intention.dart';

enum NotificationType {
  amen('Amen', '✨'),
  supportMessage('Encouragement', '💬'),
  answered('Answered Prayer', '🌅');

  const NotificationType(this.displayName, this.icon);

  final String displayName;
  final String icon;

  static NotificationType fromString(String? val) {
    if (val == null) return NotificationType.amen;
    return NotificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => NotificationType.amen,
    );
  }
}

class PrayerNotification {
  const PrayerNotification({
    required this.id,
    required this.recipientUid,
    required this.senderUid,
    required this.senderName,
    this.senderAvatarUrl,
    required this.intentionId,
    required this.intentionText,
    required this.category,
    required this.type,
    this.messageText,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String recipientUid;
  final String senderUid;
  final String senderName;
  final String? senderAvatarUrl;
  final String intentionId;
  final String intentionText;
  final PrayerCategory category;
  final NotificationType type;
  final String? messageText;
  final DateTime createdAt;
  final bool isRead;

  PrayerNotification copyWith({
    String? id,
    String? recipientUid,
    String? senderUid,
    String? senderName,
    String? senderAvatarUrl,
    String? intentionId,
    String? intentionText,
    PrayerCategory? category,
    NotificationType? type,
    String? messageText,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return PrayerNotification(
      id: id ?? this.id,
      recipientUid: recipientUid ?? this.recipientUid,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      intentionId: intentionId ?? this.intentionId,
      intentionText: intentionText ?? this.intentionText,
      category: category ?? this.category,
      type: type ?? this.type,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientUid': recipientUid,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'intentionId': intentionId,
      'intentionText': intentionText,
      'category': category.name,
      'type': type.name,
      'messageText': messageText,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  factory PrayerNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    DateTime readTime(Object? value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback;
    }

    return PrayerNotification(
      id: snapshot.id,
      recipientUid: data['recipientUid'] as String? ?? '',
      senderUid: data['senderUid'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Anonymous Believer',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      intentionId: data['intentionId'] as String? ?? '',
      intentionText: data['intentionText'] as String? ?? '',
      category: PrayerCategory.fromString(data['category'] as String?),
      type: NotificationType.fromString(data['type'] as String?),
      messageText: data['messageText'] as String?,
      createdAt: readTime(data['createdAt'], DateTime.now()),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
