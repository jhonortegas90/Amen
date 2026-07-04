import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/prayer_reflection.dart';

class LibraryRepository {
  static final List<PrayerReflection> _seedItems = [
    PrayerReflection(
      id: 'p1',
      title: 'Morning Prayer for Wisdom & Light',
      category: 'Morning',
      timeOfDay: TimeOfDayTag.morning,
      tags: ['wisdom', 'morning', 'guidance', 'peace'],
      author: 'Ancient Liturgy',
      readTimeMinutes: 2,
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
      timeOfDay: TimeOfDayTag.anytime,
      tags: ['anxiety', 'peace', 'calm', 'trust'],
      author: 'Contemplative Prayer',
      readTimeMinutes: 3,
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
      timeOfDay: TimeOfDayTag.anytime,
      tags: ['healing', 'health', 'restoration', 'faith'],
      author: 'St. Francis Tradition',
      readTimeMinutes: 2,
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
      timeOfDay: TimeOfDayTag.evening,
      tags: ['evening', 'rest', 'sleep', 'surrender'],
      author: 'Benedictine Wisdom',
      readTimeMinutes: 3,
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
      timeOfDay: TimeOfDayTag.anytime,
      tags: ['strength', 'courage', 'perseverance', 'hope'],
      author: 'Desert Fathers',
      readTimeMinutes: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      body: '''
Lord God, You are my fortress when walls crumble around me.
Grant me fortitude to stand firm, courage to face difficulty, and faith to see beyond present hardships.
For when I am weak, Your strength is made perfect.
Amen.
''',
    ),
  ];

  List<PrayerReflection> getItems({
    String? category,
    String? searchQuery,
    TimeOfDayTag? timeOfDay,
  }) {
    return _seedItems.where((item) {
      if (category != null && category != 'All' && item.category != category) {
        return false;
      }
      if (timeOfDay != null && item.timeOfDay != timeOfDay) {
        return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchBody = item.body.toLowerCase().contains(query);
        final matchTags = item.tags.any((t) => t.toLowerCase().contains(query));
        return matchTitle || matchBody || matchTags;
      }
      return true;
    }).toList();
  }

  List<String> get categories => ['All', 'Morning', 'Anxiety & Peace', 'Healing', 'Evening', 'Strength'];
}

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});
