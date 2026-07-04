import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModerationService {
  static final RegExp _blockedTerms = RegExp(
    r'\b(fuck|shit|bitch|asshole|kill yourself|suicide bait)\b',
    caseSensitive: false,
  );

  bool isAllowed(String text) => !_blockedTerms.hasMatch(text);
}

final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService();
});
