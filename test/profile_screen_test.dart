import 'package:amen/src/features/auth/data/auth_repository.dart';
import 'package:amen/src/features/profile/presentation/profile_screen.dart';
import 'package:amen/src/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget({required List<dynamic> overrides}) {
    return ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ProfileScreen()),
      ),
    );
  }

  group('ProfileScreen Widgets and States Tests', () {
    testWidgets('renders Guest Account View when user is anonymous or null', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            authStateProvider.overrideWithValue(
              const AsyncValue.data(
                AppUser(uid: 'guest-uid', isAnonymous: true),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find Guest Onboarding and welcome messages
      expect(find.text('Begin Your Journey'), findsOneWidget);
      expect(find.text('Guest Account'), findsOneWidget);
      expect(find.textContaining('Sign in to synchronize your prayers'), findsOneWidget);
      expect(find.text('Sign In / Connect Account'), findsOneWidget);

      // Should NOT find stats or account settings section
      expect(find.text('Spiritual Journey'), findsNothing);
      expect(find.text('Account Settings'), findsNothing);
    });

    testWidgets('renders Authenticated User View with Stats when user is signed in', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          overrides: [
            authStateProvider.overrideWithValue(
              const AsyncValue.data(
                AppUser(
                  uid: 'user-uid',
                  isAnonymous: false,
                  displayName: 'Blessed Pilgrim',
                  email: 'pilgrim@amen.com',
                ),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should find user information card
      expect(find.text('Blessed Pilgrim'), findsOneWidget);
      expect(find.text('pilgrim@amen.com'), findsOneWidget);
      expect(find.text('Faithful Pilgrim'), findsOneWidget);

      // Should find stats dashboard section
      expect(find.text('SPIRITUAL JOURNEY'), findsOneWidget);
      expect(find.text('Days Streak'), findsOneWidget);
      expect(find.text('Shared'), findsOneWidget);
      expect(find.text('Amens'), findsOneWidget);

      // Should find sections
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('ABOUT & LEGAL'), findsOneWidget);
      expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
    });
  });
}
