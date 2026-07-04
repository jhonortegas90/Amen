import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/amen_colors.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../../../localization/app_localizations.dart';
import '../../../shared/presentation/audio_toggle_button.dart';
import '../../../shared/services/audio_service.dart';
import '../../ads/data/ads_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_modal.dart';
import '../data/intentions_repository.dart';
import '../domain/intention.dart';
import 'widgets/amen_background.dart';
import 'widgets/amen_feedback_modal.dart';
import 'widgets/compose_sheet.dart';
import 'widgets/intention_card.dart';
import 'widgets/sponsored_pause.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _adAfterIndex = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.watch(intentionsRepositoryProvider);
    final uid = ref.watch(authRepositoryProvider).currentUid;
    final bootstrap = ref.watch(firebaseBootstrapProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AmenBackground()),
          SafeArea(
            bottom: false,
            child: StreamBuilder<List<Intention>>(
              stream: repository.watchGlobalWall(),
              builder: (context, snapshot) {
                final intentions = snapshot.data ?? const <Intention>[];
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(isLive: bootstrap.isLive, ref: ref),
                    ),
                    if (!bootstrap.isLive)
                      SliverToBoxAdapter(
                        child: _DemoBanner(message: l10n.demoMode),
                      ),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        intentions.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (intentions.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyState(message: l10n.oneWorld),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 160),
                        sliver: SliverList.builder(
                          itemCount:
                              intentions.length +
                              (intentions.length > _adAfterIndex ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (intentions.length > _adAfterIndex &&
                                index == _adAfterIndex + 1) {
                              return const SponsoredPause();
                            }
                            final offset =
                                intentions.length > _adAfterIndex &&
                                    index > _adAfterIndex + 1
                                ? 1
                                : 0;
                            final intention = intentions[index - offset];
                            return IntentionCard(
                              intention: intention,
                              isMine: intention.authorUid == uid,
                              onAmen: () async {
                                await repository.sayAmen(intention.id);
                                await ref.read(audioServiceProvider).playAmenChime();
                                if (context.mounted) {
                                  showAmenFeedbackModal(context, intention);
                                }
                              },
                              onPin: () async {
                                final rewarded = await ref
                                    .read(adsServiceProvider)
                                    .showRewardedForPin();
                                if (rewarded) {
                                  await repository.pinIntention(intention.id);
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: 24,
            bottom: 32,
            child: _ComposeFAB(onTap: () => showComposeSheet(context, ref)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isLive, required this.ref});

  final bool isLive;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined, color: AmenColors.amenGold),
                tooltip: 'Prayers & Reflections Library',
                onPressed: () => context.push('/library'),
              ),
              const AudioToggleButton(),
              IconButton(
                icon: const Icon(Icons.person_outline, color: AmenColors.amenGold),
                tooltip: 'Account & Identity',
                onPressed: () => showAuthModal(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Icon(
            Icons.auto_awesome,
            color: AmenColors.amenGold,
            size: 28,
            semanticLabel: l10n.appName,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.globalEchoWall,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              letterSpacing: 2.2,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.anonymousUnited.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              letterSpacing: 1.1,
              color: AmenColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AmenColors.blueMist.withValues(alpha: 0.09),
          border: Border.all(
            color: AmenColors.blueMist.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ComposeFAB extends StatelessWidget {
  const _ComposeFAB({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.sharePrayer,
      hint: l10n.sharePrayer,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AmenColors.night.withValues(alpha: 0.8),
            border: Border.all(
              color: AmenColors.amenGold.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AmenColors.night.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AmenColors.amenGold.withValues(alpha: 0.15),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.edit_outlined, 
                color: AmenColors.amenGold, 
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.sharePrayer,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AmenColors.amenGold,
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
