enum TimeOfDayTag {
  morning('Morning Devotional', '🌅'),
  afternoon('Midday Peace', '☀️'),
  evening('Evening Rest', '🌙'),
  anytime('Anytime', '✨');

  const TimeOfDayTag(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

class PrayerReflection {
  const PrayerReflection({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.tags,
    required this.timeOfDay,
    required this.author,
    required this.readTimeMinutes,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final List<String> tags;
  final TimeOfDayTag timeOfDay;
  final String author;
  final int readTimeMinutes;
  final DateTime createdAt;
}
