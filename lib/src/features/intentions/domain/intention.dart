import 'package:cloud_firestore/cloud_firestore.dart';

enum PrayerCategory {
  general('General', '✨'),
  healing('Healing', '🕊️'),
  grief('Comfort & Grief', '🤍'),
  gratitude('Gratitude', '🌅'),
  strength('Strength & Courage', '⛰️'),
  peace('Peace in Anxiety', '🍃'),
  guidance('Guidance', '🧭');

  const PrayerCategory(this.displayName, this.icon);

  final String displayName;
  final String icon;

  static PrayerCategory fromString(String? val) {
    if (val == null) return PrayerCategory.general;
    return PrayerCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PrayerCategory.general,
    );
  }
}

class Intention {
  const Intention({
    required this.id,
    required this.authorUid,
    required this.text,
    required this.createdAt,
    required this.amenCount,
    required this.isPinned,
    this.pinnedUntil,
    required this.locale,
    required this.status,
    this.category = PrayerCategory.general,
    this.isAnonymous = true,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String authorUid;
  final String text;
  final DateTime createdAt;
  final int amenCount;
  final bool isPinned;
  final DateTime? pinnedUntil;
  final String locale;
  final String status;
  final PrayerCategory category;
  final bool isAnonymous;
  final String? authorName;
  final String? authorAvatarUrl;

  bool get isCurrentlyPinned {
    if (!isPinned) return false;
    final until = pinnedUntil;
    return until == null || until.isAfter(DateTime.now());
  }

  Intention copyWith({
    String? id,
    String? authorUid,
    String? text,
    DateTime? createdAt,
    int? amenCount,
    bool? isPinned,
    DateTime? pinnedUntil,
    String? locale,
    String? status,
    PrayerCategory? category,
    bool? isAnonymous,
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return Intention(
      id: id ?? this.id,
      authorUid: authorUid ?? this.authorUid,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      amenCount: amenCount ?? this.amenCount,
      isPinned: isPinned ?? this.isPinned,
      pinnedUntil: pinnedUntil ?? this.pinnedUntil,
      locale: locale ?? this.locale,
      status: status ?? this.status,
      category: category ?? this.category,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }

  factory Intention.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    DateTime readTime(Object? value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback;
    }

    return Intention(
      id: snapshot.id,
      authorUid: data['authorUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: readTime(data['createdAt'], DateTime.now()),
      amenCount: data['amenCount'] as int? ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      pinnedUntil: data['pinnedUntil'] == null
          ? null
          : readTime(data['pinnedUntil'], DateTime.now()),
      locale: data['locale'] as String? ?? 'en',
      status: data['status'] as String? ?? 'approved',
      category: PrayerCategory.fromString(data['category'] as String?),
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      authorName: data['authorName'] as String?,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
    );
  }
}
