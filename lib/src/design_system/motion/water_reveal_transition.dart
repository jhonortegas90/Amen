import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../amen_colors.dart';
import 'water_curves.dart';
import 'water_reveal_clipper.dart';

/// Screen reveal container that renders a water-rise reveal animation
/// when transitioning between top-level tabs.
class WaterRevealTransition extends StatelessWidget {
  const WaterRevealTransition({
    super.key,
    required this.child,
    required this.animation,
    this.isExiting = false,
  });

  final Widget child;

  /// Animation driving the reveal progress (0.0 -> 1.0).
  final Animation<double> animation;

  /// True if this page is transitioning out (fading & drifting up slightly).
  final bool isExiting;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final rawVal = animation.value;

        // Accessibility fallback: clean crossfade without water deformation
        if (disableAnimations) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ).value;
          return Opacity(
            opacity: isExiting
                ? (1.0 - fade).clamp(0.0, 1.0)
                : fade.clamp(0.0, 1.0),
            child: child,
          );
        }

        if (isExiting) {
          // Outgoing screen: subtle upward drift (-8px) and smooth fade
          final fadeOut = (1.0 - rawVal).clamp(0.0, 1.0);
          final translateY = -8.0 * rawVal;

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(opacity: fadeOut, child: child),
          );
        }

        // Incoming screen: rising curved water-line mask + subtle settle translation
        final curvedProgress = AmenWaterCurves.screenRise.transform(rawVal);
        final translateY = 12.0 * (1.0 - curvedProgress);
        final opacity = (rawVal * 1.5).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(0, translateY),
              child: Opacity(
                opacity: opacity,
                child: ClipPath(
                  clipper: WaterRevealClipper(
                    progress: curvedProgress,
                    wavePhase: rawVal,
                  ),
                  child: child,
                ),
              ),
            ),

            // Fine golden edge border & light reflection along the rising water transition edge
            if (curvedProgress > 0.02 && curvedProgress < 0.98)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _WaterEdgeReflectionPainter(
                      progress: curvedProgress,
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

/// Renders a serene fine golden color edge border and light reflection line
/// along the rising water reveal line.
class _WaterEdgeReflectionPainter extends CustomPainter {
  _WaterEdgeReflectionPainter({
    required this.progress,
    this.wavePhase = 0.0,
  });

  final double progress;
  final double wavePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final yBase = size.height * (1.0 - progress);
    final amplitude = 10.0 * (1.0 - progress);

    final cp1X = size.width * 0.35;
    final cp1Y = yBase - amplitude * math.sin(wavePhase * math.pi * 2 + 0.5);

    final cp2X = size.width * 0.65;
    final cp2Y = yBase + amplitude * math.cos(wavePhase * math.pi * 2);

    final endY = yBase - amplitude * 0.3;

    final path = Path()
      ..moveTo(0, yBase + amplitude * 0.5)
      ..cubicTo(cp1X, cp1Y, cp2X, cp2Y, size.width, endY);

    final alphaMultiplier = (1.0 - progress).clamp(0.0, 1.0);

    // Soft ambient light band below the rising water edge
    final rect = Rect.fromLTWH(0, yBase - amplitude - 4, size.width, 16);
    final ambientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AmenColors.amenGold.withValues(alpha: 0.12 * alphaMultiplier),
          AmenColors.blueMist.withValues(alpha: 0.08 * alphaMultiplier),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, ambientPaint);

    // Soft outer gold glow stroke along the curved water transition line
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = AmenColors.amenGold.withValues(alpha: 0.32 * alphaMultiplier)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(path, glowPaint);

    // Fine golden color edge border stroke directly tracing the water transition edge
    final fineGoldBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          AmenColors.amenGold.withValues(alpha: 0.30 * alphaMultiplier),
          AmenColors.goldLight.withValues(alpha: 0.95 * alphaMultiplier),
          AmenColors.amenGold.withValues(alpha: 0.95 * alphaMultiplier),
          AmenColors.goldLight.withValues(alpha: 0.95 * alphaMultiplier),
          AmenColors.amenGold.withValues(alpha: 0.30 * alphaMultiplier),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, yBase - 15, size.width, 30));

    canvas.drawPath(path, fineGoldBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterEdgeReflectionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.wavePhase != wavePhase;
  }
}

