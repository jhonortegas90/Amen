import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amen/src/design_system/motion/water_droplet_reveal_clipper.dart';
import 'package:amen/src/design_system/motion/water_ripple_page_route.dart';

void main() {
  group('WaterDropletRevealClipper', () {
    const size = Size(400, 800);
    const origin = Offset(350, 60);

    test('returns empty path when progress is 0.0', () {
      final clipper = WaterDropletRevealClipper(progress: 0.0, origin: origin);
      final path = clipper.getClip(size);

      expect(path.getBounds().isEmpty, isTrue);
    });

    test('returns full rect path when progress is 1.0', () {
      final clipper = WaterDropletRevealClipper(progress: 1.0, origin: origin);
      final path = clipper.getClip(size);
      final bounds = path.getBounds();

      expect(bounds.width, equals(size.width));
      expect(bounds.height, equals(size.height));
    });

    test('returns expanding curved path around origin when progress is 0.5', () {
      final clipper = WaterDropletRevealClipper(progress: 0.5, origin: origin);
      final path = clipper.getClip(size);
      final bounds = path.getBounds();

      expect(bounds.isEmpty, isFalse);
      expect(bounds.contains(origin), isTrue);
    });

    test('shouldReclip triggers when progress or origin changes', () {
      final clipper1 = WaterDropletRevealClipper(progress: 0.2, origin: origin);
      final clipper2 = WaterDropletRevealClipper(progress: 0.5, origin: origin);
      final clipper3 = WaterDropletRevealClipper(progress: 0.2, origin: const Offset(100, 100));

      expect(clipper1.shouldReclip(clipper2), isTrue);
      expect(clipper1.shouldReclip(clipper3), isTrue);
    });
  });

  group('WaterRipplePageTransition Widget', () {
    testWidgets('renders child safely during reveal transition animation', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 400),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: WaterRipplePageTransition(
            animation: controller,
            secondaryAnimation: kAlwaysDismissedAnimation,
            origin: const Offset(350, 60),
            child: const Text('Notifications Target Screen'),
          ),
        ),
      );

      expect(find.text('Notifications Target Screen'), findsOneWidget);

      controller.value = 0.5;
      await tester.pump();

      expect(find.text('Notifications Target Screen'), findsOneWidget);

      controller.value = 1.0;
      await tester.pump();

      expect(find.text('Notifications Target Screen'), findsOneWidget);
    });

    testWidgets('respects disableAnimations for accessibility fallback', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 400),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: WaterRipplePageTransition(
            animation: controller,
            secondaryAnimation: kAlwaysDismissedAnimation,
            origin: const Offset(350, 60),
            child: const Text('Accessible Target Screen'),
          ),
        ),
      );

      expect(find.text('Accessible Target Screen'), findsOneWidget);
    });
  });
}
