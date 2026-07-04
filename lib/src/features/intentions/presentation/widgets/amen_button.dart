import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../design_system/amen_motion.dart';
import '../../../../localization/app_localizations.dart';

class AmenButton extends StatefulWidget {
  const AmenButton({
    super.key,
    required this.count,
    required this.onPressed,
    this.large = false,
  });

  final int count;
  final Future<void> Function() onPressed;
  final bool large;

  @override
  State<AmenButton> createState() => _AmenButtonState();
}

class _AmenButtonState extends State<AmenButton>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _loopController;
  var _pressed = false;
  var _locked = false;
  var _optimisticCount = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: AmenMotion.slow,
    );
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loopController.stop();
    } else if (!_loopController.isAnimating) {
      _loopController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AmenButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _optimisticCount = 0;
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_locked) return;
    setState(() {
      _locked = true;
      _optimisticCount = 1;
    });
    await Haptics.vibrate(HapticsType.light);
    _glowController.forward(from: 0);
    try {
      await widget.onPressed();
      await Haptics.vibrate(HapticsType.success);
    } finally {
      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 420));
        setState(() => _locked = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final visibleCount = widget.count + _optimisticCount;

    return Semantics(
      button: true,
      enabled: !_locked,
      label: '${l10n.amen}, $visibleCount',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _tap,
        child: AnimatedScale(
          scale: _pressed && !disableAnimations ? 0.92 : 1,
          duration: disableAnimations ? Duration.zero : AmenMotion.fast,
          curve: AmenMotion.curve,
          child: AnimatedBuilder(
            animation: Listenable.merge([_glowController, _loopController]),
            builder: (context, child) {
              final glow = Curves.easeOut.transform(_glowController.value);
              final loop = Curves.easeInOutSine.transform(_loopController.value);
              final totalGlow = glow + (loop * 0.4);
              
              return Container(
                width: widget.large ? 104.0 : null,
                height: widget.large ? 104.0 : 36.0,
                padding: widget.large ? null : const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  shape: widget.large ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.large ? null : BorderRadius.circular(18),
                  color: AmenColors.night.withValues(alpha: 0.78),
                  border: Border.all(color: AmenColors.amenGold, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AmenColors.amenGold.withValues(
                        alpha: (0.15 + totalGlow * 0.32).clamp(0.0, 1.0),
                      ),
                      blurRadius: widget.large ? 16 + totalGlow * 34 : 10 + totalGlow * 15,
                      spreadRadius: widget.large ? 1 + totalGlow * 7 : totalGlow * 3,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: widget.large
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 25,
                        color: AmenColors.amenGold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.amen,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      if (visibleCount > 0)
                        Text(
                          _formatCount(visibleCount),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AmenColors.amenGold.withValues(alpha: 0.86),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 16,
                        color: AmenColors.amenGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.amen,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                      if (visibleCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          _formatCount(visibleCount),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AmenColors.amenGold.withValues(alpha: 0.86),
                            fontSize: 12,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
