import 'package:amen/src/design_system/amen_colors.dart';
import 'package:amen/src/features/notifications/data/notifications_repository.dart';
import 'package:amen/src/features/shell/presentation/widgets/amen_top_bar.dart';
import 'package:amen/src/localization/app_localizations.dart';
import 'package:amen/src/shared/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudioMutedNotifier extends AudioMutedNotifier {
  @override
  bool build() => true;
}

void main() {
  Widget buildTestableWidget({
    required int unreadCount,
  }) {
    return ProviderScope(
      overrides: [
        unreadNotificationsCountProvider.overrideWithValue(unreadCount),
        audioMutedNotifierProvider.overrideWith(FakeAudioMutedNotifier.new),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AmenTopBar(),
        ),
      ),
    );
  }

  group('Notifications Icon Color Tests', () {
    testWidgets('notification icon is muted when there are no unread notifications', (tester) async {
      await tester.pumpWidget(buildTestableWidget(unreadCount: 0));
      await tester.pump();

      final iconFinder = find.byIcon(Icons.notifications_none_rounded);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, equals(AmenColors.mutedText));
    });

    testWidgets('notification icon turns gold when there are unread notifications', (tester) async {
      await tester.pumpWidget(buildTestableWidget(unreadCount: 5));
      await tester.pump();

      final iconFinder = find.byIcon(Icons.notifications_none_rounded);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, equals(AmenColors.amenGold));
    });
  });
}
