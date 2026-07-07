import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalJournalState {
  const PersonalJournalState({
    required this.activeRequests,
    required this.answeredRequests,
    required this.gratitudeItems,
  });

  const PersonalJournalState.initial()
    : activeRequests = const [],
      answeredRequests = const [],
      gratitudeItems = const [];

  final List<String> activeRequests;
  final List<String> answeredRequests;
  final List<String> gratitudeItems;

  PersonalJournalState copyWith({
    List<String>? activeRequests,
    List<String>? answeredRequests,
    List<String>? gratitudeItems,
  }) {
    return PersonalJournalState(
      activeRequests: activeRequests ?? this.activeRequests,
      answeredRequests: answeredRequests ?? this.answeredRequests,
      gratitudeItems: gratitudeItems ?? this.gratitudeItems,
    );
  }
}

class PersonalJournalNotifier extends Notifier<PersonalJournalState> {
  static const _activeKey = 'journal_active_requests';
  static const _answeredKey = 'journal_answered_requests';
  static const _gratitudeKey = 'journal_gratitude_items';

  @override
  PersonalJournalState build() {
    Future.microtask(_load);
    return const PersonalJournalState.initial();
  }

  Future<void> addActiveRequest(String text) async {
    state = state.copyWith(activeRequests: [text, ...state.activeRequests]);
    await _save();
  }

  Future<void> markAnswered(String request) async {
    state = state.copyWith(
      activeRequests: [
        for (final item in state.activeRequests)
          if (item != request) item,
      ],
      answeredRequests: [request, ...state.answeredRequests],
    );
    await _save();
  }

  Future<void> addGratitude(String text) async {
    state = state.copyWith(gratitudeItems: [text, ...state.gratitudeItems]);
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final initial = const PersonalJournalState.initial();
    state = PersonalJournalState(
      activeRequests: prefs.getStringList(_activeKey) ?? initial.activeRequests,
      answeredRequests:
          prefs.getStringList(_answeredKey) ?? initial.answeredRequests,
      gratitudeItems:
          prefs.getStringList(_gratitudeKey) ?? initial.gratitudeItems,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_activeKey, state.activeRequests);
    await prefs.setStringList(_answeredKey, state.answeredRequests);
    await prefs.setStringList(_gratitudeKey, state.gratitudeItems);
  }
}

final personalJournalProvider =
    NotifierProvider<PersonalJournalNotifier, PersonalJournalState>(
      PersonalJournalNotifier.new,
    );
