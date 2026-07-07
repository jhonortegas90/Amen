import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_button_label.dart';
import '../../../design_system/amen_colors.dart';
import '../../../design_system/amen_motion.dart';
import '../../../localization/app_localizations.dart';
import '../data/personal_journal_notifier.dart';

enum _JournalSection { active, answered, gratitude }

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _gratitudeController = TextEditingController();
  var _section = _JournalSection.active;
  var _goldFade = false;

  @override
  void dispose() {
    _gratitudeController.dispose();
    super.dispose();
  }

  void _submitGratitude() {
    final text = _gratitudeController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(personalJournalProvider.notifier).addGratitude(text);
    setState(() {
      _gratitudeController.clear();
      _section = _JournalSection.gratitude;
    });
  }

  Future<void> _markAnswered(String request) async {
    HapticFeedback.mediumImpact();
    setState(() => _goldFade = true);
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    await ref.read(personalJournalProvider.notifier).markAnswered(request);
    setState(() {
      _section = _JournalSection.answered;
      _goldFade = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final journal = ref.watch(personalJournalProvider);

    return AnimatedContainer(
      duration: AmenMotion.medium,
      curve: AmenMotion.curve,
      color: _goldFade
          ? AmenColors.amenGold.withValues(alpha: 0.10)
          : Colors.transparent,
      child: CustomScrollView(
        key: const PageStorageKey('journal-scroll'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
            sliver: SliverList.list(
              children: [
                Text(
                  l10n.journal,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.journalSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _JournalSummaryGrid(
                  active: journal.activeRequests.length,
                  answered: journal.answeredRequests.length,
                  gratitude: journal.gratitudeItems.length,
                ),
                const SizedBox(height: 18),
                _GratitudeInput(
                  controller: _gratitudeController,
                  onSubmit: _submitGratitude,
                ),
                const SizedBox(height: 18),
                _JournalSectionTabs(
                  selected: _section,
                  onSelected: (section) {
                    setState(() => _section = section);
                  },
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: AmenMotion.medium,
                  child: switch (_section) {
                    _JournalSection.active => _ActiveRequestsList(
                      key: const ValueKey('active-requests'),
                      requests: journal.activeRequests,
                      onAnswered: _markAnswered,
                    ),
                    _JournalSection.answered => _AnsweredArchive(
                      key: const ValueKey('answered-archive'),
                      requests: journal.answeredRequests,
                    ),
                    _JournalSection.gratitude => _GratitudeTimeline(
                      key: const ValueKey('gratitude-timeline'),
                      items: journal.gratitudeItems,
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalSectionTabs extends StatelessWidget {
  const _JournalSectionTabs({required this.selected, required this.onSelected});

  final _JournalSection selected;
  final ValueChanged<_JournalSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (
        section: _JournalSection.active,
        icon: Icons.timelapse_rounded,
        label: l10n.activeLabel,
        key: const ValueKey('journal-section-active-label'),
      ),
      (
        section: _JournalSection.answered,
        icon: Icons.check_circle_outline_rounded,
        label: l10n.answeredLabel,
        key: const ValueKey('journal-section-answered-label'),
      ),
      (
        section: _JournalSection.gratitude,
        icon: Icons.favorite_border_rounded,
        label: l10n.gratitudeLabel,
        key: const ValueKey('journal-section-gratitude-label'),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.nightElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AmenColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              for (var index = 0; index < tabs.length; index++) ...[
                Expanded(
                  child: _JournalSectionTab(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    labelKey: tabs[index].key,
                    selected: selected == tabs[index].section,
                    onTap: () => onSelected(tabs[index].section),
                  ),
                ),
                if (index < tabs.length - 1)
                  SizedBox(
                    height: 48,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AmenColors.line.withValues(alpha: 0.82),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalSectionTab extends StatelessWidget {
  const _JournalSectionTab({
    required this.icon,
    required this.label,
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Key labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AmenColors.night : AmenColors.mutedText;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: foreground,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AmenColors.amenGold : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon),
                  const SizedBox(width: 7),
                  Flexible(
                    child: AmenButtonLabel(
                      label,
                      key: labelKey,
                      style: labelStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalSummaryGrid extends StatelessWidget {
  const _JournalSummaryGrid({
    required this.active,
    required this.answered,
    required this.gratitude,
  });

  final int active;
  final int answered;
  final int gratitude;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricTile(value: '$active', label: l10n.activeLabel),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricTile(value: '$answered', label: l10n.answeredLabel),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricTile(value: '$gratitude', label: l10n.gratitudeLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AmenColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AmenColors.amenGold),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GratitudeInput extends StatelessWidget {
  const _GratitudeInput({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.glass.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.gratitudeHint,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            IconButton.filled(
              onPressed: onSubmit,
              icon: const Icon(Icons.arrow_upward_rounded),
              tooltip: l10n.saveGratitude,
              style: IconButton.styleFrom(
                backgroundColor: AmenColors.amenGold,
                foregroundColor: AmenColors.night,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRequestsList extends StatelessWidget {
  const _ActiveRequestsList({
    super.key,
    required this.requests,
    required this.onAnswered,
  });

  final List<String> requests;
  final ValueChanged<String> onAnswered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (requests.isEmpty) {
      return _JournalEmptyState(
        icon: Icons.timelapse_rounded,
        title: l10n.activeJournalEmptyTitle,
        description: l10n.activeJournalEmptyBody,
      );
    }

    return Column(
      children: [
        for (final request in requests)
          _JournalRow(
            icon: Icons.timelapse_rounded,
            title: l10n.journalEntry(request),
            trailing: TextButton.icon(
              onPressed: () => onAnswered(request),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(l10n.answeredLabel),
            ),
          ),
      ],
    );
  }
}

class _AnsweredArchive extends StatelessWidget {
  const _AnsweredArchive({super.key, required this.requests});

  final List<String> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (requests.isEmpty) {
      return _JournalEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: l10n.answeredJournalEmptyTitle,
        description: l10n.answeredJournalEmptyBody,
      );
    }

    return Column(
      children: [
        for (final request in requests)
          _JournalRow(
            icon: Icons.check_circle_rounded,
            title: l10n.journalEntry(request),
            subtitle: l10n.archivedWithGratitude,
          ),
      ],
    );
  }
}

class _GratitudeTimeline extends StatelessWidget {
  const _GratitudeTimeline({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (items.isEmpty) {
      return _JournalEmptyState(
        icon: Icons.favorite_border_rounded,
        title: l10n.gratitudeJournalEmptyTitle,
        description: l10n.gratitudeJournalEmptyBody,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          TweenAnimationBuilder<double>(
            key: ValueKey('gratitude-${items[index]}-$index'),
            tween: Tween(begin: 0, end: 1),
            duration: AmenMotion.medium,
            curve: AmenMotion.curve,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _JournalRow(
              icon: Icons.favorite_rounded,
              title: l10n.journalEntry(items[index]),
              subtitle: index == 0 ? l10n.justNow : l10n.savedThisWeek,
            ),
          ),
      ],
    );
  }
}

class _JournalEmptyState extends StatelessWidget {
  const _JournalEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AmenColors.glass.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AmenColors.amenGold.withValues(alpha: 0.13),
                child: Icon(icon, color: AmenColors.amenGold, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AmenColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AmenColors.glass.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
        ),
        child: ListTile(
          minLeadingWidth: 44,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: AmenColors.amenGold.withValues(alpha: 0.13),
            child: Icon(icon, color: AmenColors.amenGold),
          ),
          title: Text(title),
          subtitle: subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!),
                ),
          trailing: trailing,
        ),
      ),
    );
  }
}
