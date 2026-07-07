import 'package:amen/src/features/auth/data/auth_repository.dart';
import 'package:amen/src/features/auth/presentation/onboarding_screen.dart';
import 'package:amen/src/features/intentions/domain/intention.dart';
import 'package:amen/src/features/intentions/presentation/widgets/compose_sheet.dart';
import 'package:amen/src/features/journal/presentation/journal_screen.dart';
import 'package:amen/src/features/notifications/presentation/notifications_screen.dart';
import 'package:amen/src/features/notifications/presentation/widgets/send_support_message_modal.dart';
import 'package:amen/src/features/shell/presentation/app_shell.dart';
import 'package:amen/src/firebase/firebase_bootstrap.dart';
import 'package:amen/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const locales = AppLocalizations.supportedLocales;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLocalized(
    WidgetTester tester,
    Locale locale,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapResult(isLive: false),
          ),
          authStateProvider.overrideWithValue(
            const AsyncValue.data(AppUser.demoUser),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(_takeOverflow(tester), isNull);
  }

  for (final locale in locales) {
    testWidgets('shell tab buttons fit in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpLocalized(tester, locale, const AppShell());

      for (final label in _bottomTabLabels(locale)) {
        await tester.tap(find.text(label).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(_takeOverflow(tester), isNull);
      }
    });

    testWidgets('notification buttons fit in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpLocalized(tester, locale, const NotificationsScreen());
    });

    testWidgets('journal section buttons fit in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpLocalized(tester, locale, const JournalScreen());

      for (final tab in _journalSectionTabs(locale)) {
        final label = find.descendant(
          of: find.byKey(tab.key),
          matching: find.text(tab.label),
        );
        expect(label, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
        );
      }
    });

    testWidgets('onboarding buttons fit in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpLocalized(tester, locale, const OnboardingScreen());
    });

    testWidgets('compose and support buttons fit in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpLocalized(tester, locale, const ComposeSheet());
      await pumpLocalized(
        tester,
        locale,
        SendSupportMessageModal(
          intention: Intention(
            id: 'layout-intention',
            authorUid: 'author',
            text: 'Please pray for patience and courage today.',
            createdAt: DateTime(2026, 1, 1),
            amenCount: 3,
            isPinned: false,
            locale: locale.languageCode,
            status: 'approved',
            category: PrayerCategory.guidance,
          ),
        ),
      );
    });
  }
}

List<String> _bottomTabLabels(Locale locale) {
  return switch (locale.languageCode) {
    'es' => ['Altar', 'Comunidad', 'Orar', 'Diario', 'Perfil'],
    'fr' => ['Autel', 'Communauté', 'Prier', 'Journal', 'Profil'],
    _ => ['Altar', 'Community', 'Pray', 'Journal', 'Profile'],
  };
}

List<({String label, Key key})> _journalSectionTabs(Locale locale) {
  return switch (locale.languageCode) {
    'es' => _journalSectionTabData('Activas', 'Respondidas', 'Gratitud'),
    'fr' => _journalSectionTabData('Actives', 'Exaucées', 'Gratitude'),
    _ => _journalSectionTabData('Active', 'Answered', 'Gratitude'),
  };
}

List<({String label, Key key})> _journalSectionTabData(
  String active,
  String answered,
  String gratitude,
) {
  return [
    (label: active, key: const ValueKey('journal-section-active-label')),
    (label: answered, key: const ValueKey('journal-section-answered-label')),
    (label: gratitude, key: const ValueKey('journal-section-gratitude-label')),
  ];
}

Object? _takeOverflow(WidgetTester tester) {
  Object? firstOverflow;
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    if (exception.toString().contains('overflowed')) {
      firstOverflow ??= exception;
    }
  }
  return firstOverflow;
}
