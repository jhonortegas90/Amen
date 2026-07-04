import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/amen_colors.dart';

class AmenBackground extends StatefulWidget {
  const AmenBackground({super.key});

  @override
  State<AmenBackground> createState() => _AmenBackgroundState();
}

class _AmenBackgroundState extends State<AmenBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AmenBackgroundPainter(
            progress: reduceMotion ? 0 : _controller.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _AmenBackgroundPainter extends CustomPainter {
  const _AmenBackgroundPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AmenColors.night, AmenColors.deepSpace, Color(0xFF060810)],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final topLight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.08),
        radius: 0.78,
        colors: [
          AmenColors.warmGold.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, topLight);

    final bottomLight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.92),
        radius: 0.58,
        colors: [
          AmenColors.amenGold.withValues(alpha: 0.28),
          AmenColors.blueMist.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bottomLight);

    final center = Offset(size.width / 2, size.height * 0.9);
    for (var i = 0; i < 8; i++) {
      final radius = 28.0 + (i * 18) + math.sin(progress * math.pi * 2) * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AmenColors.amenGold.withValues(alpha: 0.18 - i * 0.014);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2.8,
          height: radius * 0.58,
        ),
        paint,
      );
    }

    final sparkPaint = Paint()
      ..color = AmenColors.amenGold.withValues(alpha: 0.5);
    for (var i = 0; i < 22; i++) {
      final x = (i * 53.0) % size.width;
      final y = size.height * (0.18 + ((i * 19) % 58) / 100);
      final alpha = 0.14 + 0.2 * math.sin(progress * math.pi * 2 + i);
      sparkPaint.color = AmenColors.amenGold.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.3, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmenBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
