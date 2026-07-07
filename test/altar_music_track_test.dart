import 'package:amen/src/features/altar/domain/altar_music_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AltarMusicTrack Tests', () {
    test('toFirestore maps properties correctly', () {
      final track = AltarMusicTrack(
        id: 't1',
        title: 'Still Waters ', // note the trailing space
        artist: ' Amen Worship ', // note the leading/trailing spaces
        audioUrl: 'https://test.audio/url.mp3',
        audioPath: 'music/t1.mp3',
        isActive: true,
        sortOrder: 15,
      );

      final map = track.toFirestore();
      
      expect(map['title'], equals('Still Waters')); // trimmed
      expect(map['artist'], equals('Amen Worship')); // trimmed
      expect(map['audioUrl'], equals('https://test.audio/url.mp3'));
      expect(map['audioPath'], equals('music/t1.mp3'));
      expect(map['isActive'], isTrue);
      expect(map['sortOrder'], equals(15));
      expect(map['updatedAt'], isNotNull);
    });

    test('copyWith overrides specified properties', () {
      final track = AltarMusicTrack(
        id: 't1',
        title: 'Track A',
        artist: 'Artist A',
        audioUrl: 'https://a.mp3',
        audioPath: 'a.mp3',
        isActive: true,
        sortOrder: 1,
      );

      final updated = track.copyWith(
        title: 'Track B',
        isActive: false,
        sortOrder: 2,
      );

      expect(updated.id, equals('t1')); // unchanged
      expect(updated.artist, equals('Artist A')); // unchanged
      expect(updated.audioUrl, equals('https://a.mp3')); // unchanged
      expect(updated.title, equals('Track B')); // updated
      expect(updated.isActive, isFalse); // updated
      expect(updated.sortOrder, equals(2)); // updated
    });
  });
}
