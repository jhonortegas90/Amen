import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../design_system/motion/water_curves.dart';

/// Custom water-inspired bottom navigation bar featuring a liquid horizontal selector,
/// droplet stretch/compression physics, concentric water ripple feedback, and
/// warm gold visual highlights.
class WaterBottomNavigation extends StatefulWidget {
  const WaterBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.labels,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<String> labels;

  static const List<IconData> icons = [
    Icons.church_outlined,
    Icons.groups_2_outlined,
    Icons.volunteer_activism_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  State<WaterBottomNavigation> createState() => _WaterBottomNavigationState();
}

class _WaterBottomNavigationState extends State<WaterBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _selectorController;
  late AnimationController _rippleController;
  late AnimationController _iconScaleController;

  double _selectorStartIndex = 0;
  double _selectorTargetIndex = 0;
  int _rippleIndex = 0;
  var _iconPulseGeneration = 0;

  @override
  void initState() {
    super.initState();
    _selectorStartIndex = widget.selectedIndex.toDouble();
    _selectorTargetIndex = widget.selectedIndex.toDouble();
    _rippleIndex = widget.selectedIndex;

    _selectorController = AnimationController(
      vsync: this,
      duration: AmenWaterCurves.selectorDuration,
      value: 1.0,
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: AmenWaterCurves.rippleDuration,
    );

    _iconScaleController = AnimationController(
      vsync: this,
      duration: AmenWaterCurves.iconColorDuration,
    );
  }

  @override
  void didUpdateWidget(covariant WaterBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _navigateTo(widget.selectedIndex);
    }
  }

  void _navigateTo(int newIndex) {
    if (newIndex.toDouble() == _selectorTargetIndex &&
        !_selectorController.isAnimating) {
      return;
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final currentVisualIndex = _currentSelectorIndex();

    HapticFeedback.lightImpact();

    setState(() {
      _selectorStartIndex = currentVisualIndex;
      _selectorTargetIndex = newIndex.toDouble();
      _rippleIndex = newIndex;
    });

    _selectorController.duration = disableAnimations
        ? AmenWaterCurves.reducedMotionDuration
        : AmenWaterCurves.selectorDuration;
    _selectorController.forward(from: 0.0);
    if (!disableAnimations) {
      _rippleController.forward(from: 0.0);
    }
    _pulseSelectedIcon();
  }

  double _currentSelectorIndex() {
    final progress = AmenWaterCurves.selectorEase.transform(
      _selectorController.value,
    );
    return _selectorStartIndex +
        (_selectorTargetIndex - _selectorStartIndex) * progress;
  }

  void _pulseSelectedIcon() {
    final generation = ++_iconPulseGeneration;
    _iconScaleController.forward(from: 0.0).whenComplete(() {
      if (mounted && generation == _iconPulseGeneration) {
        _iconScaleController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _selectorController.dispose();
    _rippleController.dispose();
    _iconScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottomPadding),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AmenColors.night.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AmenColors.line.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: AmenColors.night.withValues(alpha: 0.65),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AmenColors.amenGold.withValues(alpha: 0.08),
                blurRadius: 36,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final tabCount = widget.labels.length;
              final itemWidth = totalWidth / tabCount;

              return AnimatedBuilder(
                animation: Listenable.merge([
                  _selectorController,
                  _rippleController,
                  _iconScaleController,
                ]),
                builder: (context, child) {
                  final selectorProgress = disableAnimations
                      ? Curves.easeInOut.transform(_selectorController.value)
                      : AmenWaterCurves.selectorEase.transform(
                          _selectorController.value,
                        );

                  final rippleProgress = disableAnimations
                      ? 1.0
                      : AmenWaterCurves.rippleExpand.transform(
                          _rippleController.value,
                        );

                  final iconScaleProgress = disableAnimations
                      ? 0.0
                      : AmenWaterCurves.iconPulse.transform(
                          _iconScaleController.value,
                        );

                  return Stack(
                    children: [
                      // Layer 1: Water Selector (Droplet Glide)
                      CustomPaint(
                        size: Size(totalWidth, 64),
                        painter: _WaterSelectorPainter(
                          startIndex: _selectorStartIndex,
                          targetIndex: _selectorTargetIndex,
                          progress: selectorProgress,
                          itemWidth: itemWidth,
                          disableAnimations: disableAnimations,
                        ),
                      ),

                      // Layer 2: Concentric Water Ripple on Target Destination
                      if (!disableAnimations && _rippleController.isAnimating)
                        CustomPaint(
                          size: Size(totalWidth, 64),
                          painter: _WaterRipplePainter(
                            targetIndex: _rippleIndex,
                            progress: rippleProgress,
                            itemWidth: itemWidth,
                          ),
                        ),

                      // Layer 3: Interactive Tab Buttons & Icons
                      Row(
                        children: List.generate(tabCount, (index) {
                          final isSelected = widget.selectedIndex == index;
                          final isEmphasized = index == 2; // Center Pray hub

                          final iconScale = isSelected
                              ? 1.0 +
                                    (0.05 * iconScaleProgress).clamp(0.0, 0.08)
                              : 1.0;

                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: widget.labels[index],
                              child: InkWell(
                                onTap: () {
                                  if (index == widget.selectedIndex) return;
                                  widget.onSelected(index);
                                },
                                borderRadius: BorderRadius.circular(24),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.scale(
                                        scale: iconScale,
                                        child: TweenAnimationBuilder<Color?>(
                                          tween: ColorTween(
                                            end: isSelected
                                                ? AmenColors.amenGold
                                                : AmenColors.mutedText,
                                          ),
                                          duration:
                                              AmenWaterCurves.iconColorDuration,
                                          curve: Curves.easeInOut,
                                          builder: (context, color, _) {
                                            final iconData =
                                                (index == 2 && isSelected)
                                                ? Icons
                                                      .volunteer_activism_rounded
                                                : WaterBottomNavigation
                                                      .icons[index];
                                            return Icon(
                                              iconData,
                                              size: isEmphasized ? 22 : 20,
                                              color: color,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: AnimatedDefaultTextStyle(
                                          duration:
                                              AmenWaterCurves.iconColorDuration,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AmenColors.amenGold
                                                : AmenColors.mutedText,
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                          child: Text(widget.labels[index]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// CustomPainter drawing the liquid horizontal selector droplet as it glides
/// across tabs with organic stretching and compression.
class _WaterSelectorPainter extends CustomPainter {
  _WaterSelectorPainter({
    required this.startIndex,
    required this.targetIndex,
    required this.progress,
    required this.itemWidth,
    required this.disableAnimations,
  });

  final double startIndex;
  final double targetIndex;
  final double progress;
  final double itemWidth;
  final bool disableAnimations;

  @override
  void paint(Canvas canvas, Size size) {
    final startX = (startIndex + 0.5) * itemWidth;
    final endX = (targetIndex + 0.5) * itemWidth;
    final currentX = startX + (endX - startX) * progress;

    final distance = (targetIndex - startIndex).abs();
    final isMoving = distance > 0 && progress > 0.0 && progress < 1.0;

    // Base droplet dimensions - sized to fully enclose both icon and label comfortably
    final baseWidth = math.min(itemWidth * 0.90, itemWidth - 4.0);
    final baseHeight = size.height - 12.0;
    final centerY = size.height / 2;

    double stretchFactor = 1.0;
    double compressFactor = 1.0;

    if (isMoving && !disableAnimations) {
      // Sine wave peak at progress = 0.5 for fluid stretch/compress feel
      final movementPhase = math.sin(progress * math.pi);
      stretchFactor = 1.0 + (0.20 * movementPhase * math.min(distance, 2));
      compressFactor = 1.0 - (0.08 * movementPhase);
    }

    final currentWidth = math.min(baseWidth * stretchFactor, itemWidth - 2.0);
    final currentHeight = baseHeight * compressFactor;

    final rect = Rect.fromCenter(
      center: Offset(currentX, centerY),
      width: currentWidth,
      height: currentHeight,
    );

    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(16),
    );

    // Dual layer water glow
    final glowPaint = Paint()
      ..color = AmenColors.amenGold.withValues(alpha: isMoving ? 0.25 : 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMoving ? 8.0 : 4.0);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AmenColors.amenGold.withValues(alpha: 0.18),
          AmenColors.blueMist.withValues(alpha: 0.09),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    // Fine golden color edge border for liquid selector droplet transition
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          AmenColors.goldLight.withValues(alpha: isMoving ? 0.85 : 0.55),
          AmenColors.amenGold.withValues(alpha: isMoving ? 0.95 : 0.65),
          AmenColors.goldLight.withValues(alpha: isMoving ? 0.85 : 0.55),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterSelectorPainter oldDelegate) {
    return oldDelegate.startIndex != startIndex ||
        oldDelegate.targetIndex != targetIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.disableAnimations != disableAnimations;
  }
}

/// Renders a single low-opacity concentric water ripple that expands outwards
/// behind the newly selected destination icon and fades cleanly out.
class _WaterRipplePainter extends CustomPainter {
  _WaterRipplePainter({
    required this.targetIndex,
    required this.progress,
    required this.itemWidth,
  });

  final int targetIndex;
  final double progress;
  final double itemWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final centerX = (targetIndex + 0.5) * itemWidth;
    final centerY = size.height / 2;

    final minRadius = 12.0;
    final maxRadius = itemWidth * 0.48;
    final currentRadius = minRadius + (maxRadius - minRadius) * progress;

    final alpha = (1.0 - progress) * 0.35;

    // Fine golden color edge border for concentric water ripple transition
    final rippleBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AmenColors.goldLight.withValues(
        alpha: (alpha * 2.2).clamp(0.0, 0.90),
      );

    final rippleGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..color = AmenColors.amenGold.withValues(
        alpha: (alpha * 1.2).clamp(0.0, 0.45),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final innerGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AmenColors.blueMist.withValues(
        alpha: (alpha * 0.4).clamp(0.0, 1.0),
      );

    canvas.drawCircle(
      Offset(centerX, centerY),
      currentRadius * 0.6,
      innerGlowPaint,
    );
    canvas.drawCircle(Offset(centerX, centerY), currentRadius, rippleGlowPaint);
    canvas.drawCircle(
      Offset(centerX, centerY),
      currentRadius,
      rippleBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterRipplePainter oldDelegate) {
    return oldDelegate.targetIndex != targetIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.itemWidth != itemWidth;
  }
}
