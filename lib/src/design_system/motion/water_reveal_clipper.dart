import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom clipper that creates a rising water-line reveal mask with a shallow,
/// broad curved edge. The wave flattens out as [progress] reaches 1.0.
class WaterRevealClipper extends CustomClipper<Path> {
  WaterRevealClipper({required this.progress, this.wavePhase = 0.0});

  /// Transition progress from 0.0 (fully hidden at bottom) to 1.0 (fully revealed).
  final double progress;

  /// Optional subtle phase movement for dynamic liquid feel.
  final double wavePhase;

  @override
  Path getClip(Size size) {
    if (progress >= 0.999) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    if (progress <= 0.001) {
      return Path();
    }

    final path = Path();

    // The water line rises from size.height down to 0.0.
    final yBase = size.height * (1.0 - progress);

    // Shallow wave amplitude: max ~10px, decaying to 0px near completion.
    final amplitude = 10.0 * (1.0 - progress);

    // Control point offsets for a broad, tranquil curve across the screen width.
    final cp1X = size.width * 0.35;
    final cp1Y = yBase - amplitude * math.sin(wavePhase * math.pi * 2 + 0.5);

    final cp2X = size.width * 0.65;
    final cp2Y = yBase + amplitude * math.cos(wavePhase * math.pi * 2);

    final endY = yBase - amplitude * 0.3;

    // Start at left water edge
    path.moveTo(0, yBase + amplitude * 0.5);

    // Smooth cubic bezier across top edge of rising reveal surface
    path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, size.width, endY);

    // Down to screen bottom and back to origin
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WaterRevealClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.wavePhase != wavePhase;
  }
}
