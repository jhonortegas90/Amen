import 'package:flutter/material.dart';

import '../../../../design_system/amen_colors.dart';
import '../config/onboarding_config.dart';

class AnimatedCollageBackground extends StatefulWidget {
  const AnimatedCollageBackground({super.key});

  @override
  State<AnimatedCollageBackground> createState() =>
      _AnimatedCollageBackgroundState();
}

class _AnimatedCollageBackgroundState extends State<AnimatedCollageBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = OnboardingConfig.collageImages;
    final chunk = (images.length / 3).ceil();

    final col1 = images.sublist(0, chunk);
    final col2 = images.sublist(chunk, (chunk * 2).clamp(0, images.length));
    final col3 = images.sublist((chunk * 2).clamp(0, images.length));

    return Stack(
      children: [
        // 3-Column Staggered Masonry Grid with subtle 6px dark gaps
        Row(
          children: [
            Expanded(
              child: _LoopingCollageColumn(
                animation: _controller,
                images: col1,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _LoopingCollageColumn(
                animation: _controller,
                images: col2,
                reverse: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _LoopingCollageColumn(
                animation: _controller,
                images: col3,
                phase: 0.34,
              ),
            ),
          ],
        ),

        // Dark Warm Vignette Overlay to ensure text legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AmenColors.night.withValues(alpha: 0.65),
                  AmenColors.night.withValues(alpha: 0.35),
                  AmenColors.night.withValues(alpha: 0.88),
                ],
                stops: const [0.0, 0.45, 0.85],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoopingCollageColumn extends StatelessWidget {
  const _LoopingCollageColumn({
    required this.animation,
    required this.images,
    this.reverse = false,
    this.phase = 0,
  });

  static const double _gap = 6;

  final Animation<double> animation;
  final List<String> images;
  final bool reverse;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileHeight = constraints.maxWidth / 0.70;
        final cycleHeight = images.length * (tileHeight + _gap);

        return ClipRect(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final progress = (animation.value + phase) % 1.0;
              final travel = progress * cycleHeight;
              final offset = reverse ? -cycleHeight + travel : -travel;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(top: offset, left: 0, right: 0, child: child!),
                ],
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var cycle = 0; cycle < 3; cycle++)
                  for (final url in images)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _gap),
                      child: SizedBox(
                        height: tileHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AmenColors.nightElevated,
                                  child: const Center(
                                    child: Icon(
                                      Icons.wb_sunny_outlined,
                                      color: AmenColors.amenGold,
                                      size: 24,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
