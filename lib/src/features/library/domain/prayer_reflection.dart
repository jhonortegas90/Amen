import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeOfDayTag {
  morning('Morning Devotional', '🌅'),
  afternoon('Midday Peace', '☀️'),
  evening('Evening Rest', '🌙'),
  anytime('Anytime', '✨');

  const TimeOfDayTag(this.displayName, this.icon);
  final String displayName;
  final String icon;

  static TimeOfDayTag fromName(String? value) {
    return TimeOfDayTag.values.firstWhere(
      (tag) => tag.name == value,
      orElse: () => TimeOfDayTag.anytime,
    );
  }
}

class PrayerCatalogCategory {
  const PrayerCatalogCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.isActive,
    this.backgroundImageUrl,
    this.backgroundImagePath,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final int sortOrder;
  final bool isActive;
  final String? backgroundImageUrl;
  final String? backgroundImagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static PrayerCatalogCategory fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PrayerCatalogCategory(
      id: stringValue(data['id'], fallback: doc.id),
      title: stringValue(data['title'], fallback: 'Untitled catalog'),
      description: stringValue(data['description']),
      sortOrder: intValue(data['sortOrder'], fallback: 0),
      isActive: boolValue(data['isActive'], fallback: true),
      backgroundImageUrl: nullableString(data['backgroundImageUrl']),
      backgroundImagePath: nullableString(data['backgroundImagePath']),
      createdAt: dateValue(data['createdAt']),
      updatedAt: dateValue(data['updatedAt']),
    );
  }

  PrayerCatalogCategory copyWith({
    String? id,
    String? title,
    String? description,
    int? sortOrder,
    bool? isActive,
    String? backgroundImageUrl,
    String? backgroundImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrayerCatalogCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PrayerReflection {
  const PrayerReflection({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.categoryId,
    required this.tags,
    required this.timeOfDay,
    required this.author,
    required this.readTimeMinutes,
    required this.createdAt,
    required this.sortOrder,
    required this.isActive,
    this.categoryDescription = '',
    this.backgroundImageUrl,
    this.backgroundImagePath,
    this.audioUrl,
    this.audioPath,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String categoryId;
  final String categoryDescription;
  final List<String> tags;
  final TimeOfDayTag timeOfDay;
  final String author;
  final int readTimeMinutes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int sortOrder;
  final bool isActive;
  final String? backgroundImageUrl;
  final String? backgroundImagePath;
  final String? audioUrl;
  final String? audioPath;

  static PrayerReflection fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PrayerReflection(
      id: stringValue(data['id'], fallback: doc.id),
      title: stringValue(data['title'], fallback: 'Untitled prayer'),
      body: stringValue(data['body']),
      category: stringValue(data['categoryTitle'], fallback: 'Prayer'),
      categoryId: stringValue(data['categoryId']),
      categoryDescription: stringValue(data['categoryDescription']),
      tags: stringListValue(data['tags']),
      timeOfDay: TimeOfDayTag.fromName(nullableString(data['timeOfDay'])),
      author: stringValue(data['author'], fallback: 'Amen'),
      readTimeMinutes: intValue(data['readTimeMinutes'], fallback: 2),
      createdAt:
          dateValue(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: dateValue(data['updatedAt']),
      sortOrder: intValue(data['sortOrder'], fallback: 0),
      isActive: boolValue(data['isActive'], fallback: true),
      backgroundImageUrl: nullableString(data['backgroundImageUrl']),
      backgroundImagePath: nullableString(data['backgroundImagePath']),
      audioUrl: nullableString(data['audioUrl']),
      audioPath: nullableString(data['audioPath']),
    );
  }

  PrayerReflection copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? categoryId,
    String? categoryDescription,
    List<String>? tags,
    TimeOfDayTag? timeOfDay,
    String? author,
    int? readTimeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? isActive,
    String? backgroundImageUrl,
    String? backgroundImagePath,
    String? audioUrl,
    String? audioPath,
  }) {
    return PrayerReflection(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      tags: tags ?? this.tags,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      author: author ?? this.author,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      audioUrl: audioUrl ?? this.audioUrl,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}

String stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

String? nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int intValue(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool boolValue(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  return fallback;
}

List<String> stringListValue(Object? value) {
  if (value is Iterable) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

DateTime? dateValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
