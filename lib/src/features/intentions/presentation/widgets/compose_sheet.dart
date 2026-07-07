import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../design_system/amen_button_label.dart';
import '../../../../localization/app_localizations.dart';
import '../../../ads/data/ads_service.dart';
import '../../../community/data/community_notifier.dart';
import '../../../journal/data/personal_journal_notifier.dart';
import '../../../moderation/data/moderation_service.dart';
import '../../data/intentions_repository.dart';
import '../../domain/intention.dart';

enum ComposeScope { public, circle, journal }

Future<void> showComposeSheet(BuildContext context, WidgetRef ref, {String? defaultCircleId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ComposeSheet(defaultCircleId: defaultCircleId),
  );
}

class ComposeSheet extends ConsumerStatefulWidget {
  const ComposeSheet({super.key, this.defaultCircleId});

  final String? defaultCircleId;

  @override
  ConsumerState<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<ComposeSheet> {
  static const maxLength = 250;

  final _controller = TextEditingController();
  var _submitting = false;
  PrayerCategory _selectedCategory = PrayerCategory.general;
  var _scope = ComposeScope.public;
  String? _selectedCircleId;
  var _isAnonymous = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.defaultCircleId != null) {
      _scope = ComposeScope.circle;
      _selectedCircleId = widget.defaultCircleId;
    } else {
      // Set to first circle if any exists, but default to public
      final circles = ref.read(communityStateProvider).circles;
      if (circles.isNotEmpty) {
        _selectedCircleId = circles.first.id;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();

    setState(() => _error = null);
    if (text.isEmpty) {
      setState(() => _error = l10n.emptyPrayer);
      return;
    }
    if (text.length > maxLength) {
      setState(() => _error = l10n.tooLong);
      return;
    }
    if (!ref.read(moderationServiceProvider).isAllowed(text)) {
      setState(() => _error = l10n.blockedPrayer);
      return;
    }

    if (_scope == ComposeScope.circle && _selectedCircleId == null) {
      setState(() => _error = 'Please select a circle to post to.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      if (_scope == ComposeScope.public) {
        await ref
            .read(intentionsRepositoryProvider)
            .createIntention(
              text,
              locale,
              category: _selectedCategory,
              isAnonymous: _isAnonymous,
            );
      } else if (_scope == ComposeScope.circle) {
        await ref.read(communityStateProvider.notifier).shareIntentionToCircle(
              circleId: _selectedCircleId!,
              text: text,
              category: _selectedCategory,
              isAnonymous: _isAnonymous,
            );
      } else {
        await ref.read(personalJournalProvider.notifier).addActiveRequest(text);
      }

      await HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.of(context).pop();
        String successMessage = l10n.publicRequestSent;
        if (_scope == ComposeScope.circle) {
          final circle = ref.read(communityStateProvider).circles.firstWhere(
                (c) => c.id == _selectedCircleId,
                orElse: () => throw Exception('Circle not found'),
              );
          successMessage = 'Prayer shared to ${circle.name}';
        } else if (_scope == ComposeScope.journal) {
          successMessage = l10n.privateRequestSaved;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AmenColors.nightElevated,
          ),
        );
      }
      if (_scope == ComposeScope.public) {
        await ref.read(adsServiceProvider).showInterstitialAfterPost();
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString().split('\n').first;
        setState(
          () => _error = message.length > 80
              ? '${message.substring(0, 77)}...'
              : message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final remaining = maxLength - _controller.text.length;
    final communityState = ref.watch(communityStateProvider);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        decoration: const BoxDecoration(
          color: AmenColors.deepSpace,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AmenColors.line,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.composeTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              
              // 3-tab scope selector (Public, Circle, Private Journal)
              SegmentedButton<ComposeScope>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<ComposeScope>(
                    value: ComposeScope.public,
                    icon: const Icon(Icons.public_rounded),
                    label: AmenButtonLabel(l10n.publicLabel),
                  ),
                  const ButtonSegment<ComposeScope>(
                    value: ComposeScope.circle,
                    icon: Icon(Icons.group_outlined),
                    label: AmenButtonLabel('Circle'),
                  ),
                  ButtonSegment<ComposeScope>(
                    value: ComposeScope.journal,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: AmenButtonLabel(l10n.privateLabel),
                  ),
                ],
                selected: {_scope},
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AmenColors.night
                        : AmenColors.mutedText;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AmenColors.amenGold
                        : AmenColors.nightElevated;
                  }),
                ),
                onSelectionChanged: (selection) {
                  setState(() {
                    _scope = selection.first;
                    // Auto-select circle if switching to circle tab and none selected
                    if (_scope == ComposeScope.circle && _selectedCircleId == null && communityState.circles.isNotEmpty) {
                      _selectedCircleId = communityState.circles.first.id;
                    }
                  });
                },
              ),
              
              const SizedBox(height: 14),
              
              // Circle Selector Dropdown if Circle tab is selected
              if (_scope == ComposeScope.circle) ...[
                if (communityState.circles.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'You have not joined any private circles yet. Go to the Community tab to create or join one.',
                      style: TextStyle(color: AmenColors.danger, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const Text(
                    'SELECT TARGET CIRCLE',
                    style: TextStyle(
                      color: AmenColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: AmenColors.nightElevated,
                    initialValue: _selectedCircleId,
                    borderRadius: BorderRadius.circular(24),
                    style: Theme.of(context).textTheme.bodyLarge,
                    items: communityState.circles.map((circle) {
                      return DropdownMenuItem<String>(
                        value: circle.id,
                        child: Text(circle.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCircleId = val);
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
              
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                activeThumbColor: AmenColors.amenGold,
                title: Text(l10n.submitAnonymously),
                subtitle: Text(
                  _isAnonymous ? l10n.shownWithoutName : l10n.linkedToProfile,
                ),
                onChanged: (value) => setState(() => _isAnonymous = value),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.categoryTopic,
                style: const TextStyle(
                  color: AmenColors.mutedText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: PrayerCategory.values.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          '${cat.icon} ${l10n.prayerCategory(cat.displayName)}',
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor: AmenColors.amenGold.withValues(
                          alpha: 0.25,
                        ),
                        backgroundColor: AmenColors.nightElevated,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AmenColors.amenGold
                              : AmenColors.mutedText,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AmenColors.amenGold
                              : AmenColors.blueMist.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: maxLength,
                onChanged: (_) => setState(() {}),
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: l10n.composeHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _error == null
                          ? Text(
                              '$remaining',
                              key: const ValueKey('remaining'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : Text(
                              _error!,
                              key: ValueKey(_error),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AmenColors.danger),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: (_submitting || (_scope == ComposeScope.circle && _selectedCircleId == null)) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                    label: AmenButtonLabel(l10n.postPrayer),
                    style: FilledButton.styleFrom(
                      backgroundColor: AmenColors.amenGold,
                      foregroundColor: AmenColors.night,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
