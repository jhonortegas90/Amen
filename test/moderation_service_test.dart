import 'package:amen/src/features/moderation/data/moderation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows calm prayer text', () {
    final service = ModerationService();
    expect(
      service.isAllowed('Praying for courage and healing tonight.'),
      isTrue,
    );
  });

  test('blocks obvious abusive terms', () {
    final service = ModerationService();
    expect(service.isAllowed('Please kill yourself'), isFalse);
  });
}
