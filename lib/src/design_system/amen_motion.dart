import 'package:flutter/animation.dart';

class AmenMotion {
  const AmenMotion._();

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 520);
  static const entrance = Duration(milliseconds: 720);

  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
}
