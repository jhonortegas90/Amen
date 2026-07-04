import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/amen_colors.dart';
import '../data/auth_repository.dart';
import 'config/onboarding_config.dart';
import 'widgets/animated_collage_background.dart';
import 'widgets/legal_terms_modal.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithApple();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AmenColors.night,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedCollageBackground()),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 720;
                final logoSize = isCompact ? 140.0 : 172.0;
                final messageWidth = math.min(
                  constraints.maxWidth * 0.86,
                  382.0,
                );
                final authWidth = math.min(constraints.maxWidth * 0.98, 472.0);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12.8 : 14.4,
                    vertical: isCompact ? 8 : 11.2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.5,
                        child: Image.asset(
                          'assets/images/AppLogo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),

                      const Spacer(flex: 1),

                      SizedBox(
                        width: messageWidth,
                        child: _GlassmorphicCard(
                          borderRadius: 28,
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 22 : 24,
                            vertical: isCompact ? 20 : 23,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Discover Your Daily\nPath to Peace',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 20 : 22,
                                  height: 1.18,
                                  letterSpacing: 0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.32,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Guided prayers, community, spiritual reflection, and mindful moments await you on this path.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  height: 1.34,
                                  fontSize: isCompact ? 14.5 : 15.5,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      if (_error != null) ...[
                        SizedBox(
                          width: authWidth,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: AmenColors.amenGold,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: authWidth,
                          child: _GlassmorphicCard(
                            borderRadius: 34,
                            padding: EdgeInsets.fromLTRB(
                              isCompact ? 18 : 22,
                              isCompact ? 18 : 22,
                              isCompact ? 18 : 22,
                              isCompact ? 18 : 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AuthPillButton(
                                  onPressed: _handleGoogleSignIn,
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF111111),
                                  icon: Image.asset(
                                    'assets/images/google_g_logo.png',
                                    width: 23,
                                    height: 23,
                                    filterQuality: FilterQuality.high,
                                  ),
                                  label: OnboardingConfig.googleButtonText,
                                ),
                                const SizedBox(height: 14),
                                _AuthPillButton(
                                  onPressed: _handleAppleSignIn,
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  icon: const Icon(
                                    Icons.apple,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  label: OnboardingConfig.appleButtonText,
                                ),
                                const SizedBox(height: 21),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _LegalLink(
                                      text: OnboardingConfig.privacyPolicyTitle,
                                      onTap: () => showLegalTermsModal(
                                        context,
                                        isPrivacy: true,
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    _LegalLink(
                                      text:
                                          OnboardingConfig.termsOfServiceTitle,
                                      onTap: () => showLegalTermsModal(
                                        context,
                                        isPrivacy: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: isCompact ? 0 : 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPillButton extends StatelessWidget {
  const _AuthPillButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 26, height: 26, child: Center(child: icon)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.34),
            decorationThickness: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Premium glass panel with blurred backdrop, tinted fill, and gradient glow.
class _GlassmorphicCard extends StatelessWidget {
  const _GlassmorphicCard({
    required this.child,
    required this.borderRadius,
    required this.padding,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AmenColors.warmGold.withValues(alpha: 0.22),
            blurRadius: 34,
            spreadRadius: -6,
            offset: const Offset(12, 16),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: -10,
            offset: const Offset(-12, -10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            padding: const EdgeInsets.all(1.15),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.60),
                  AmenColors.warmGold.withValues(alpha: 0.56),
                  Colors.white.withValues(alpha: 0.10),
                  AmenColors.warmGold.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.27, 0.58, 1.0],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius - 1.15),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFF4C6).withValues(alpha: 0.15),
                            const Color(0xFF252116).withValues(alpha: 0.43),
                            const Color(0xFF090B10).withValues(alpha: 0.68),
                            const Color(0xFF2C2416).withValues(alpha: 0.48),
                          ],
                          stops: const [0.0, 0.28, 0.62, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.84, -0.56),
                          radius: 1.1,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.32, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GlassEdgePainter(borderRadius - 1.15),
                    ),
                  ),
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.7),
      Radius.circular(radius),
    );

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.52),
          Colors.white.withValues(alpha: 0.08),
          AmenColors.warmGold.withValues(alpha: 0.42),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6)
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          AmenColors.amenGold.withValues(alpha: 0.64),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}
