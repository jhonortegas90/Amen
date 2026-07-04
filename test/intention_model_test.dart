import 'package:amen/src/features/intentions/domain/intention.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pin expires after pinnedUntil', () {
    final intention = Intention(
      id: 'id',
      authorUid: 'uid',
      text: 'A prayer',
      createdAt: DateTime.now(),
      amenCount: 0,
      isPinned: true,
      pinnedUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      locale: 'en',
      status: 'approved',
    );

    expect(intention.isCurrentlyPinned, isFalse);
  });
}
