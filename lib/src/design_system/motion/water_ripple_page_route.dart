import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../amen_colors.dart';
import 'water_curves.dart';
import 'water_droplet_reveal_clipper.dart';

/// Helper function to create a [CustomTransitionPage] using the serene Water Ripple transition.
CustomTransitionPage<T> buildWaterRipplePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final origin = state.extra as Offset?;

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AmenWaterCurves.rippleDuration,
    reverseTransitionDuration: AmenWaterCurves.screenRevealDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return WaterRipplePageTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        origin: origin,
        child: child,
      );
    },
  );
}

/// Page transition widget that expands a liquid droplet reveal mask
/// from a specified [origin] point across the screen.
class WaterRipplePageTransition extends StatelessWidget {
  const WaterRipplePageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.origin,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final Offset? origin;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final rawVal = animation.value;

        if (disableAnimations) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ).value;
          return Opacity(opacity: fade.clamp(0.0, 1.0), child: child);
        }

        final curvedProgress = AmenWaterCurves.rippleExpand.transform(rawVal);
        final opacity = (rawVal * 2.0).clamp(0.0, 1.0);
        final scale = 0.96 + (0.04 * curvedProgress);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: ClipPath(
                  clipper: WaterDropletRevealClipper(
                    progress: curvedProgress,
                    origin: origin,
                    wavePhase: rawVal,
                  ),
                  child: child,
                ),
              ),
            ),

            // Fine golden color edge border & reflection along expanding droplet perimeter
            if (curvedProgress > 0.01 && curvedProgress < 0.98)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _WaterDropletEdgePainter(
                      progress: curvedProgress,
                      origin: origin,
                      wavePhase: rawVal,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Custom painter rendering glowing fine golden color edge borders and light
/// reflections along the expanding droplet perimeter.
class _WaterDropletEdgePainter extends CustomPainter {
  _WaterDropletEdgePainter({
    required this.progress,
    this.origin,
    this.wavePhase = 0.0,
  });

  final double progress;
  final Offset? origin;
  final double wavePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = origin ?? Offset(size.width - 44, 60);
    final alphaMultiplier = (1.0 - progress).clamp(0.0, 1.0);

    // Build organic droplet wave path matching WaterDropletRevealClipper
    final path = WaterDropletRevealClipper.buildDropletPath(
      center,
      progress,
      wavePhase,
      size,
    );

    // Outer blue mist glow ring
    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * (1.0 - progress * 0.5)
      ..color = AmenColors.blueMist.withValues(alpha: 0.20 * alphaMultiplier);
    canvas.drawPath(path, bluePaint);

    // Soft outer gold glow stroke
    final goldGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * (1.0 - progress * 0.4)
      ..color = AmenColors.amenGold.withValues(alpha: 0.35 * alphaMultiplier)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(path, goldGlowPaint);

    // Fine golden color edge border stroke
    final fineGoldBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AmenColors.goldLight.withValues(alpha: 0.90 * alphaMultiplier);
    canvas.drawPath(path, fineGoldBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterDropletEdgePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.wavePhase != wavePhase;
  }
}
