import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../../moderation/presentation/report_dialog.dart';
import '../../domain/intention.dart';
import 'amen_button.dart';

class IntentionCard extends ConsumerWidget {
  const IntentionCard({
    super.key,
    required this.intention,
    required this.isMine,
    required this.onAmen,
    required this.onPin,
  });

  final Intention intention;
  final bool isMine;
  final Future<void> Function() onAmen;
  final Future<void> Function() onPin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return intention.isCurrentlyPinned
        ? _PinnedIntentionCard(
            intention: intention,
            onAmen: onAmen,
            onReport: () => showReportDialog(context, ref, intention.id),
          )
        : _QuietIntentionRow(
            intention: intention,
            isMine: isMine,
            onAmen: onAmen,
            onPin: onPin,
            onReport: () => showReportDialog(context, ref, intention.id),
          );
  }
}

class _PinnedIntentionCard extends StatelessWidget {
  const _PinnedIntentionCard({
    required this.intention,
    required this.onAmen,
    required this.onReport,
  });

  final Intention intention;
  final Future<void> Function() onAmen;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AmenColors.amenGold.withValues(alpha: 0.12),
            AmenColors.glass,
          ],
          stops: const [0.0, 0.4],
        ),
        border: Border.all(color: AmenColors.amenGold.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AmenColors.amenGold.withValues(alpha: 0.15),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.push_pin,
                      size: 18,
                      color: AmenColors.amenGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.pinned,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AmenColors.amenGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AmenColors.night,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${intention.category.icon} ${intention.category.displayName}',
                        style: const TextStyle(fontSize: 11, color: AmenColors.mutedText),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, size: 18, color: AmenColors.mutedText),
                      onPressed: onReport,
                      tooltip: 'Report Post',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  intention.text,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AmenButton(
            count: intention.amenCount,
            onPressed: onAmen,
            large: true,
          ),
        ],
      ),
    );
  }
}

class _QuietIntentionRow extends StatelessWidget {
  const _QuietIntentionRow({
    required this.intention,
    required this.isMine,
    required this.onAmen,
    required this.onPin,
    required this.onReport,
  });

  final Intention intention;
  final bool isMine;
  final Future<void> Function() onAmen;
  final Future<void> Function() onPin;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AmenColors.nightElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AmenColors.blueMist.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${intention.category.icon} ${intention.category.displayName}',
                            style: const TextStyle(fontSize: 11, color: AmenColors.amenGold),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: onReport,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.flag_outlined, size: 16, color: AmenColors.mutedText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intention.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w300,
                        color: AmenColors.text.withValues(alpha: 0.9),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: onPin,
                        icon: const Icon(Icons.push_pin_outlined, size: 17),
                        label: Text(l10n.pinToTop),
                        style: TextButton.styleFrom(
                          foregroundColor: AmenColors.amenGold,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AmenButton(
                count: intention.amenCount, 
                onPressed: onAmen,
                large: false,
              ),
            ],
          ),
        ),
        // Faded Gradient Divider with Gold Dot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AmenColors.amenGold.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AmenColors.amenGold,
                boxShadow: [
                  BoxShadow(
                    color: AmenColors.amenGold.withValues(alpha: 0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AmenColors.amenGold.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
