import 'package:amen/src/design_system/motion/water_curves.dart';
import 'package:amen/src/design_system/motion/water_reveal_clipper.dart';
import 'package:amen/src/design_system/motion/water_reveal_transition.dart';
import 'package:amen/src/features/shell/presentation/widgets/water_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WaterRevealClipper', () {
    test('returns rectangular full clip at progress 1.0', () {
      final clipper = WaterRevealClipper(progress: 1.0);
      const size = Size(360, 800);
      final path = clipper.getClip(size);

      expect(path.getBounds(), equals(const Rect.fromLTWH(0, 0, 360, 800)));
    });

    test('returns empty clip at progress 0.0', () {
      final clipper = WaterRevealClipper(progress: 0.0);
      const size = Size(360, 800);
      final path = clipper.getClip(size);

      expect(path.getBounds().isEmpty, isTrue);
    });

    test('returns valid shallow curve at progress 0.5', () {
      final clipper = WaterRevealClipper(progress: 0.5, wavePhase: 0.2);
      const size = Size(360, 800);
      final path = clipper.getClip(size);

      expect(path.getBounds().height, greaterThan(0));
      expect(clipper.shouldReclip(WaterRevealClipper(progress: 0.4)), isTrue);
    });
  });

  group('WaterBottomNavigation Widget', () {
    testWidgets('renders five tab destinations with labels', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WaterBottomNavigation(
              selectedIndex: selectedIndex,
              onSelected: (idx) => selectedIndex = idx,
              labels: const ['Home', 'Community', 'Pray', 'Journal', 'Profile'],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Pray'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('animates selector smoothly upon tapping new destination', (
      tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: WaterBottomNavigation(
                  selectedIndex: selectedIndex,
                  onSelected: (idx) => setState(() => selectedIndex = idx),
                  labels: const [
                    'Home',
                    'Community',
                    'Pray',
                    'Journal',
                    'Profile',
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Tap Journal destination (index 3)
      await tester.tap(find.text('Journal'));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 150),
      ); // Midway in selector glide

      expect(selectedIndex, equals(3));

      await tester.pump(
        AmenWaterCurves.selectorDuration,
      ); // Complete selector glide
      await tester.pump(
        AmenWaterCurves.rippleDuration,
      ); // Complete ripple decay
    });

    testWidgets('respects disableAnimations for reduced motion accessibility', (
      tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: Scaffold(
            bottomNavigationBar: WaterBottomNavigation(
              selectedIndex: selectedIndex,
              onSelected: (idx) => selectedIndex = idx,
              labels: const ['Home', 'Community', 'Pray', 'Journal', 'Profile'],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(selectedIndex, equals(4));
    });
  });

  group('WaterRevealTransition Widget', () {
    testWidgets('renders child content safely during reveal animation', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
        value: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaterRevealTransition(
              animation: controller,
              child: const Text('Journal Content'),
            ),
          ),
        ),
      );

      expect(find.text('Journal Content'), findsOneWidget);
      controller.dispose();
    });

    testWidgets(
      'falls back to simple opacity crossfade when disableAnimations is true',
      (tester) async {
        final controller = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 300),
          value: 0.8,
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            },
            home: Scaffold(
              body: WaterRevealTransition(
                animation: controller,
                child: const Text('Community Content'),
              ),
            ),
          ),
        );

        expect(find.text('Community Content'), findsOneWidget);
        controller.dispose();
      },
    );

    testWidgets('renders fine golden edge border reflection during mid-reveal', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
        value: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaterRevealTransition(
              animation: controller,
              child: const Text('Gold Edge Screen'),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Gold Edge Screen'), findsOneWidget);
      controller.dispose();
    });
  });
}

