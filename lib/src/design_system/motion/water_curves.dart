import 'package:flutter/animation.dart';

/// Motion curves and timings tailored for serene, water-like UI transitions.
class AmenWaterCurves {
  const AmenWaterCurves._();

  /// Smooth ease-in-out curve for horizontal selector translation (280-360ms).
  static const Curve selectorEase = Cubic(0.22, 0.61, 0.36, 1.0);

  /// Curve governing droplet shape stretching (peaks midway during glide).
  static const Curve dropletStretch = Curves.easeInOutSine;

  /// Deceleration curve for soft concentric ripple expansion (400-550ms).
  static const Curve rippleExpand = Cubic(0.1, 0.8, 0.2, 1.0);

  /// Gentle curve for screen water-rise reveal and settling (180-420ms).
  static const Curve screenRise = Cubic(0.16, 0.84, 0.44, 1.0);

  /// Icon scale feedback curve (1.0 -> 1.05 -> 1.0).
  static const Curve iconPulse = Curves.easeOutBack;

  /// Timing constants matching guidelines (increased by 30% for natural fluid motion).
  static const Duration selectorDuration = Duration(milliseconds: 416);
  static const Duration rippleDuration = Duration(milliseconds: 624);
  static const Duration iconColorDuration = Duration(milliseconds: 260);
  static const Duration screenRevealDuration = Duration(milliseconds: 572);
  static const Duration reducedMotionDuration = Duration(milliseconds: 234);
}
