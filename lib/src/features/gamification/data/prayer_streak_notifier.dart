import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerStreakState {
  const PrayerStreakState({
    required this.currentStreak,
    required this.lastInteractionDay,
    required this.unlockedBadges,
  });

  const PrayerStreakState.initial()
    : currentStreak = 0,
      lastInteractionDay = null,
      unlockedBadges = const <String>[];

  final int currentStreak;
  final DateTime? lastInteractionDay;
  final List<String> unlockedBadges;

  PrayerStreakState copyWith({
    int? currentStreak,
    DateTime? lastInteractionDay,
    List<String>? unlockedBadges,
  }) {
    return PrayerStreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      lastInteractionDay: lastInteractionDay ?? this.lastInteractionDay,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}

class PrayerStreakNotifier extends Notifier<PrayerStreakState> {
  static const _streakKey = 'prayer_streak_current';
  static const _lastInteractionKey = 'prayer_streak_last_interaction';
  static const _badgesKey = 'prayer_streak_badges';

  @override
  PrayerStreakState build() {
    Future.microtask(_load);
    return const PrayerStreakState.initial();
  }

  Future<void> recordPrayerSupport() async {
    final today = _dateOnly(DateTime.now());
    final lastDay = state.lastInteractionDay == null
        ? null
        : _dateOnly(state.lastInteractionDay!);

    if (lastDay == today) return;

    final isConsecutive =
        lastDay != null && today.difference(lastDay).inDays == 1;
    final nextStreak = isConsecutive ? state.currentStreak + 1 : 1;
    final nextBadges = _badgesFor(nextStreak);

    state = PrayerStreakState(
      currentStreak: nextStreak,
      lastInteractionDay: today,
      unlockedBadges: nextBadges,
    );
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIso = prefs.getString(_lastInteractionKey);
    final loaded = PrayerStreakState(
      currentStreak: prefs.getInt(_streakKey) ?? 0,
      lastInteractionDay: lastIso == null ? null : DateTime.tryParse(lastIso),
      unlockedBadges: prefs.getStringList(_badgesKey) ?? const <String>[],
    );
    state = loaded;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, state.currentStreak);
    if (state.lastInteractionDay != null) {
      await prefs.setString(
        _lastInteractionKey,
        state.lastInteractionDay!.toIso8601String(),
      );
    }
    await prefs.setStringList(_badgesKey, state.unlockedBadges);
  }

  List<String> _badgesFor(int streak) {
    final badges = <String>{...state.unlockedBadges};
    if (streak >= 1) badges.add('First Prayer');
    if (streak >= 3) badges.add('Three-Day Rhythm');
    if (streak >= 7) badges.add('Week of Faithfulness');
    if (streak >= 30) badges.add('Prayer Anchor');
    return badges.toList(growable: false);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

final prayerStreakProvider =
    NotifierProvider<PrayerStreakNotifier, PrayerStreakState>(
      PrayerStreakNotifier.new,
    );
