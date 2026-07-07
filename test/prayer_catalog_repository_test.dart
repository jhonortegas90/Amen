import 'package:amen/src/features/library/data/library_repository.dart';
import 'package:amen/src/features/library/domain/prayer_reflection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prayer catalog repository', () {
    test('normalizes unsupported locales to English', () {
      expect(normalizeCatalogLocale('es-MX'), 'es');
      expect(normalizeCatalogLocale('fr_CA'), 'fr');
      expect(normalizeCatalogLocale('pt-BR'), 'en');
    });

    test('parses comma separated tags for manually authored text', () {
      expect(stringListValue('peace, healing,  hope '), [
        'peace',
        'healing',
        'hope',
      ]);
    });

    test(
      'filters demo prayers by shared category id and search text',
      () async {
        final repository = DemoLibraryRepository();

        final healing = await repository
            .watchItems(locale: 'en', categoryId: 'healing')
            .first;
        expect(healing, hasLength(1));
        expect(healing.single.categoryId, 'healing');

        final peace = await repository
            .watchItems(locale: 'en', searchQuery: 'anxiety')
            .first;
        expect(peace.single.title, contains('Anxiety'));
      },
    );
  });
}
