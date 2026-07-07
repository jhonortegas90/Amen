import 'package:flutter/material.dart';

import '../../../../design_system/amen_button_label.dart';
import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../data/scripture_bank.dart';
import '../../domain/intention.dart';
import '../../../notifications/presentation/widgets/send_support_message_modal.dart';

void showAmenFeedbackModal(BuildContext context, Intention intention) {
  final scripture = ScriptureBank.getScriptureForCategory(intention.category);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _AmenFeedbackModal(intention: intention, scripture: scripture),
  );
}

class _AmenFeedbackModal extends StatelessWidget {
  const _AmenFeedbackModal({required this.intention, required this.scripture});

  final Intention intention;
  final ScriptureItem scripture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: AmenColors.night,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AmenColors.amenGold.withValues(alpha: 0.15),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AmenColors.mutedText.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AmenColors.amenGold.withValues(alpha: 0.12),
              border: Border.all(
                color: AmenColors.amenGold.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                intention.category.icon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AmenColors.amenGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.amenConfirmed,
                style: textTheme.labelMedium?.copyWith(
                  color: AmenColors.amenGold,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.joinedPrayerFor(
              l10n.prayerCategory(intention.category.displayName),
            ),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AmenColors.mutedText),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AmenColors.nightElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AmenColors.blueMist.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '“${scripture.verse}”',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AmenColors.pureWhite,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${scripture.reference}',
                  style: textTheme.labelLarge?.copyWith(
                    color: AmenColors.amenGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  color: AmenColors.mutedText.withValues(alpha: 0.2),
                  thickness: 0.8,
                ),
                const SizedBox(height: 10),
                Text(
                  scripture.shortReflection,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AmenColors.pureWhite.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSendSupportMessageModal(context, intention);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AmenColors.pureWhite,
                    side: BorderSide(
                      color: AmenColors.amenGold.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AmenColors.amenGold,
                  ),
                  label: AmenButtonLabel(
                    l10n.leaveNote,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AmenColors.amenGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AmenButtonLabel(
                    l10n.amenAndClose,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
