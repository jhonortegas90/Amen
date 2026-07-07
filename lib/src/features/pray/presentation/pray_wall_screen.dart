import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_button_label.dart';
import '../../../design_system/amen_colors.dart';
import '../../../design_system/amen_motion.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../../../localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../ads/data/ads_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../gamification/data/prayer_streak_notifier.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/intention.dart';
import '../../intentions/presentation/widgets/compose_sheet.dart';
import '../../intentions/presentation/widgets/sponsored_pause.dart';
import '../../notifications/presentation/widgets/send_support_message_modal.dart';
import 'widgets/pray_intercession_modal.dart';

class PrayWallScreen extends ConsumerStatefulWidget {
  const PrayWallScreen({super.key});

  @override
  ConsumerState<PrayWallScreen> createState() => _PrayWallScreenState();
}

class _PrayWallScreenState extends ConsumerState<PrayWallScreen> {
  static const _pageSize = 12;
  static const _adAfterIndex = 8;

  final _scrollController = ScrollController();
  var _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < 420) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  Future<void> _prayFor(Intention intention) async {
    final repository = ref.read(intentionsRepositoryProvider);
    await repository.sayAmen(intention.id);
    await ref.read(prayerStreakProvider.notifier).recordPrayerSupport();
    await ref.read(audioServiceProvider).playAmenChime();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.watch(intentionsRepositoryProvider);
    final uid = ref.watch(authRepositoryProvider).currentUid;
    final bootstrap = ref.watch(firebaseBootstrapProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Intention>>(
        stream: repository.watchGlobalWall(),
        builder: (context, snapshot) {
          final intentions = snapshot.data ?? const <Intention>[];
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              intentions.isEmpty;
          final visibleIntentions = intentions.take(_visibleCount).toList();
          final hasMore = _visibleCount < intentions.length;

          return CustomScrollView(
            key: const PageStorageKey('pray-wall-scroll'),
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _PrayWallHeader(
                    subtitle: l10n.prayWallSubtitle,
                    onCompose: () => showComposeSheet(context, ref),
                  ),
                ),
              ),
              if (!bootstrap.isLive)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  sliver: SliverToBoxAdapter(
                    child: _PrayWallNotice(message: l10n.demoMode),
                  ),
                ),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AmenColors.amenGold,
                    ),
                  ),
                )
              else if (intentions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyPrayWall(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 156),
                  sliver: SliverList.builder(
                    itemCount:
                        visibleIntentions.length +
                        (visibleIntentions.length > _adAfterIndex ? 1 : 0) +
                        (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (visibleIntentions.length > _adAfterIndex &&
                          index == _adAfterIndex + 1) {
                        return const SponsoredPause();
                      }

                      final adOffset =
                          visibleIntentions.length > _adAfterIndex &&
                              index > _adAfterIndex + 1
                          ? 1
                          : 0;
                      final itemIndex = index - adOffset;

                      if (itemIndex >= visibleIntentions.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AmenColors.amenGold,
                            ),
                          ),
                        );
                      }

                      final intention = visibleIntentions[itemIndex];
                      return _PrayWallCard(
                        intention: intention,
                        isMine: intention.authorUid == uid,
                        onPray: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PrayIntercessionModal(
                            intention: intention,
                            onConfirm: () => _prayFor(intention),
                          ),
                        ),
                        onPin: () async {
                          final rewarded = await ref
                              .read(adsServiceProvider)
                              .showRewardedForPin();
                          if (rewarded) {
                            await repository.pinIntention(intention.id);
                          }
                        },
                        onSupport: () =>
                            showSendSupportMessageModal(context, intention),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PrayWallHeader extends StatelessWidget {
  const _PrayWallHeader({
    required this.subtitle,
    required this.onCompose,
  });

  final String subtitle;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                l10n.pray,
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onCompose();
              },
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: AmenButtonLabel(l10n.sendOutMyRequest),
              style: FilledButton.styleFrom(
                backgroundColor: AmenColors.amenGold,
                foregroundColor: AmenColors.night,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _PrayWallCard extends StatefulWidget {
  const _PrayWallCard({
    required this.intention,
    required this.isMine,
    required this.onPray,
    required this.onPin,
    required this.onSupport,
  });

  final Intention intention;
  final bool isMine;
  final Future<void> Function() onPray;
  final Future<void> Function() onPin;
  final VoidCallback onSupport;

  @override
  State<_PrayWallCard> createState() => _PrayWallCardState();
}

class _PrayWallCardState extends State<_PrayWallCard> {
  var _isPraying = false;
  var _reinforced = false;
  var _optimisticAmen = 0;

  Future<void> _handlePray() async {
    if (_isPraying) return;
    setState(() {
      _isPraying = true;
      _reinforced = true;
      _optimisticAmen = 1;
    });
    HapticFeedback.lightImpact();
    try {
      await widget.onPray();
      HapticFeedback.mediumImpact();
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _isPraying = false;
          _reinforced = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant _PrayWallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intention.amenCount != widget.intention.amenCount) {
      _optimisticAmen = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final intention = widget.intention;
    final count = intention.amenCount + _optimisticAmen;

    return AnimatedContainer(
      duration: AmenMotion.medium,
      curve: AmenMotion.curve,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _reinforced
              ? AmenColors.amenGold
              : AmenColors.line.withValues(alpha: 0.68),
          width: _reinforced ? 1.6 : 1,
        ),
        boxShadow: [
          if (_reinforced)
            BoxShadow(
              color: AmenColors.amenGold.withValues(alpha: 0.26),
              blurRadius: 32,
              spreadRadius: 4,
            )
          else
            BoxShadow(
              color: AmenColors.night.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AmenColors.nightElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AmenColors.blueMist.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${intention.category.icon} '
                  '${l10n.prayerCategory(intention.category.displayName)}',
                  style: const TextStyle(
                    color: AmenColors.amenGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (intention.isCurrentlyPinned)
                const Icon(
                  Icons.push_pin,
                  color: AmenColors.amenGold,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!intention.isAnonymous) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AmenColors.nightElevated,
                  backgroundImage: intention.authorAvatarUrl != null
                      ? NetworkImage(intention.authorAvatarUrl!)
                      : null,
                  child: intention.authorAvatarUrl == null
                      ? const Icon(Icons.person, size: 11, color: AmenColors.mutedText)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  intention.authorName ?? 'Pilgrim',
                  style: const TextStyle(
                    color: AmenColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            intention.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.46,
              color: AmenColors.text.withValues(alpha: 0.92),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 17,
                      color: AmenColors.amenGold.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.liftedUpCount(count),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onSupport,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                color: AmenColors.amenGold,
                tooltip: l10n.sendSupport,
              ),
              if (widget.isMine)
                IconButton(
                  onPressed: widget.onPin,
                  icon: const Icon(Icons.push_pin_outlined),
                  color: AmenColors.amenGold,
                  tooltip: l10n.pinToTop,
                ),
              FilledButton.icon(
                onPressed: _isPraying ? null : _handlePray,
                icon: _isPraying
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volunteer_activism_rounded, size: 17),
                label: AmenButtonLabel(l10n.prayButton),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AmenColors.amenGold,
                  foregroundColor: AmenColors.night,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  disabledBackgroundColor: AmenColors.amenGold.withValues(
                    alpha: 0.56,
                  ),
                  disabledForegroundColor: AmenColors.night,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayWallNotice extends StatelessWidget {
  const _PrayWallNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.blueMist.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AmenColors.blueMist.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _EmptyPrayWall extends StatelessWidget {
  const _EmptyPrayWall();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          l10n.noPrayerRequestsYet,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
