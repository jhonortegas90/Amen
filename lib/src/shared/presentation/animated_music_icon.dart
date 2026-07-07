import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedMusicIcon extends StatefulWidget {
  const AnimatedMusicIcon({
    super.key,
    required this.color,
    required this.isMuted,
    this.size = 20,
  });

  final Color color;
  final bool isMuted;
  final double size;

  @override
  State<AnimatedMusicIcon> createState() => _AnimatedMusicIconState();
}

class _AnimatedMusicIconState extends State<AnimatedMusicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2880),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedMusicIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMuted != widget.isMuted) {
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (widget.isMuted) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _MusicIconPainter(
              color: widget.color,
              progress: _controller.value,
              isMuted: widget.isMuted,
            ),
          );
        },
      ),
    );
  }
}

class _MusicIconPainter extends CustomPainter {
  const _MusicIconPainter({
    required this.color,
    required this.progress,
    required this.isMuted,
  });

  final Color color;
  final double progress;
  final bool isMuted;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.14;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isMuted) {
      _paintBars(canvas, size, paint, const <double>[0.34, 0.52, 0.34]);
      canvas.drawLine(
        Offset(size.width * 0.24, size.height * 0.24),
        Offset(size.width * 0.76, size.height * 0.76),
        paint,
      );
      return;
    }

    const phases = <double>[0.72, 0, 0.38];
    final heights = phases
        .map((phase) {
          final beat = math.sin((progress + phase) * math.pi * 2);
          final normalized = (beat + 1) / 2;
          return 0.26 + normalized * 0.58;
        })
        .toList(growable: false);

    _paintBars(canvas, size, paint, heights);
  }

  void _paintBars(
    Canvas canvas,
    Size size,
    Paint paint,
    List<double> heightFactors,
  ) {
    final xPositions = <double>[
      size.width * 0.28,
      size.width * 0.5,
      size.width * 0.72,
    ];

    for (var i = 0; i < xPositions.length; i += 1) {
      final barHeight = size.height * heightFactors[i];
      final centerY = size.height * 0.5;
      canvas.drawLine(
        Offset(xPositions[i], centerY - barHeight / 2),
        Offset(xPositions[i], centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MusicIconPainter oldDelegate) {
    return color != oldDelegate.color ||
        progress != oldDelegate.progress ||
        isMuted != oldDelegate.isMuted;
  }
}
