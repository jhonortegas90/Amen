import 'package:amen/src/app.dart';
import 'package:amen/src/features/auth/presentation/config/onboarding_config.dart';
import 'package:amen/src/firebase/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Amen app boots to onboarding screen with high-fidelity glass UI', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseBootstrapProvider.overrideWithValue(
            const FirebaseBootstrapResult(isLive: false),
          ),
        ],
        child: const AmenApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Onboarding Screen renders central card title & sign-in options
    expect(find.textContaining('Discover Your Daily'), findsOneWidget);
    expect(find.text(OnboardingConfig.googleButtonText), findsOneWidget);
    expect(find.text(OnboardingConfig.appleButtonText), findsOneWidget);
    expect(find.text(OnboardingConfig.privacyPolicyTitle), findsOneWidget);
    expect(find.text(OnboardingConfig.termsOfServiceTitle), findsOneWidget);
  });
}
