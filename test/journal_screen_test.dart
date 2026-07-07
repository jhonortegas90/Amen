import 'package:amen/src/features/journal/presentation/journal_screen.dart';
import 'package:amen/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Journal screen localizes visible Spanish UI and seeded content',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(body: JournalScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Diario'), findsOneWidget);
      expect(find.text('Activas'), findsWidgets);
      expect(find.text('Respondidas'), findsWidgets);
      expect(find.text('Gratitud'), findsWidgets);
      expect(find.text('Hoy doy gracias por...'), findsOneWidget);

      // Verify that the empty state is displayed initially instead of mock data
      expect(find.text('Tus peticiones activas'), findsOneWidget);
      expect(
        find.text('Sabiduría para una conversación difícil esta semana.'),
        findsNothing,
      );

      // Enter a new gratitude item and submit
      await tester.enterText(find.byType(TextField), 'Familia y salud');
      await tester.tap(find.byTooltip('Guardar gratitud'));
      await tester.pumpAndSettle();

      // Verify that gratitude tab is showing and contains our entered item
      expect(find.text('Familia y salud'), findsOneWidget);
      expect(find.text('Ahora mismo'), findsOneWidget);
    },
  );
}
