import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom clipper that creates an expanding organic water droplet/ripple reveal mask
/// centered at a specific [origin] point (such as the notification bell icon).
class WaterDropletRevealClipper extends CustomClipper<Path> {
  WaterDropletRevealClipper({
    required this.progress,
    this.origin,
    this.wavePhase = 0.0,
  });

  /// Transition progress from 0.0 (fully hidden at origin) to 1.0 (fully revealed).
  final double progress;

  /// The center point of the droplet expansion in global/screen coordinates.
  /// If null, defaults to the top-right notification icon position.
  final Offset? origin;

  /// Optional wave phase for subtle organic liquid movement along the perimeter.
  final double wavePhase;

  @override
  Path getClip(Size size) {
    if (progress >= 0.999) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    if (progress <= 0.001) {
      return Path();
    }

    final center = origin ?? Offset(size.width - 44, 60);
    return buildDropletPath(center, progress, wavePhase, size);
  }

  /// Builds the organic droplet wave path. Shared with the edge painter to ensure alignment.
  static Path buildDropletPath(Offset center, double progress, double wavePhase, Size size) {
    // Calculate maximum radius to reach the furthest screen corner from center
    final maxDx = math.max(center.dx, (size.width - center.dx).abs());
    final maxDy = math.max(center.dy, (size.height - center.dy).abs());
    final maxRadius = math.sqrt(maxDx * maxDx + maxDy * maxDy);

    final baseRadius = maxRadius * progress;

    // Organic wave amplitude peaks in the middle of expansion and decays at ends
    final amplitude = 24.0 * math.sin(progress * math.pi);

    final path = Path();
    // Increased segments for smoother, more fluid waves
    const segments = 120;
    final angleStep = (2 * math.pi) / segments;

    for (var i = 0; i <= segments; i++) {
      final angle = i * angleStep;
      // Complex organic liquid ripple combining multiple frequencies and opposite phases
      final waveOffset = amplitude * 
          (0.6 * math.sin(5 * angle - wavePhase * math.pi * 4) + 
           0.4 * math.sin(8 * angle + wavePhase * math.pi * 2.5));
      final radius = math.max(0.0, baseRadius + waveOffset);

      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaterDropletRevealClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.origin != origin ||
        oldClipper.wavePhase != wavePhase;
  }
}
