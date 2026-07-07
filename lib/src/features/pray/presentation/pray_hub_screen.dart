import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/amen_colors.dart';
import '../../../localization/app_localizations.dart';

class PrayHubScreen extends StatelessWidget {
  const PrayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      key: const PageStorageKey('pray-hub-scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          sliver: SliverList.list(
            children: [
              Text(
                l10n.prayerHub,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.takeQuietMoment,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              _PrayHubCard(
                icon: Icons.menu_book_outlined,
                title: l10n.prayerRoom,
                body:
                    'Select a prayer, adjust pace and ambience, then read in a focused teleprompter.',
                action: l10n.prayerRoom,
                onTap: () => context.push('/library'),
              ),
              const SizedBox(height: 14),
              _PrayHubCard(
                icon: Icons.explore_outlined,
                title: l10n.prayerCompass,
                body:
                    'Choose what you feel and receive a prayer, verse, ambience, and journal prompt.',
                action: l10n.prayerCompass,
                onTap: () {},
              ),
              const SizedBox(height: 14),
              _PrayHubCard(
                icon: Icons.bookmark_border_rounded,
                title: l10n.savedPrayers,
                body: 'Return to prayers you saved for later moments.',
                action: l10n.savedPrayers,
                onTap: () {},
              ),
              const SizedBox(height: 14),
              _PrayHubCard(
                icon: Icons.history_rounded,
                title: l10n.recentSessions,
                body:
                    'Continue a recent prayer room session or restart a quiet routine.',
                action: l10n.continueAction,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrayHubCard extends StatelessWidget {
  const _PrayHubCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AmenColors.amenGold.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AmenColors.amenGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AmenColors.amenGold,
                foregroundColor: AmenColors.night,
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
