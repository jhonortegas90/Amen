import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../../ads/data/ads_service.dart';
import '../../../moderation/data/moderation_service.dart';
import '../../data/intentions_repository.dart';
import '../../domain/intention.dart';

Future<void> showComposeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const ComposeSheet(),
  );
}

class ComposeSheet extends ConsumerStatefulWidget {
  const ComposeSheet({super.key});

  @override
  ConsumerState<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<ComposeSheet> {
  static const maxLength = 250;

  final _controller = TextEditingController();
  var _submitting = false;
  PrayerCategory _selectedCategory = PrayerCategory.general;
  String? _error;

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

    setState(() => _submitting = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      await ref
          .read(intentionsRepositoryProvider)
          .createIntention(text, locale, category: _selectedCategory);
      await HapticFeedback.lightImpact();
      if (mounted) Navigator.of(context).pop();
      await ref.read(adsServiceProvider).showInterstitialAfterPost();
    } catch (error) {
      if (mounted) {
        final message = error.toString().split('\n').first;
        setState(() => _error = message.length > 80 ? '${message.substring(0, 77)}...' : message);
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
              const Text(
                'Category / Topic:',
                style: TextStyle(color: AmenColors.mutedText, fontSize: 13),
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
                        label: Text('${cat.icon} ${cat.displayName}'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AmenColors.amenGold.withValues(alpha: 0.25),
                        backgroundColor: AmenColors.nightElevated,
                        labelStyle: TextStyle(
                          color: isSelected ? AmenColors.amenGold : AmenColors.mutedText,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                    label: Text(l10n.postPrayer),
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
