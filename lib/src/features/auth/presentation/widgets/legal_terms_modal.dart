import 'package:flutter/material.dart';

import '../../../../design_system/amen_button_label.dart';
import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../config/onboarding_config.dart';

void showLegalTermsModal(BuildContext context, {required bool isPrivacy}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LegalTermsModal(isPrivacy: isPrivacy),
  );
}

class _LegalTermsModal extends StatelessWidget {
  const _LegalTermsModal({required this.isPrivacy});

  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final title = isPrivacy
        ? OnboardingConfig.privacyPolicyTitle
        : OnboardingConfig.termsOfServiceTitle;

    final content = isPrivacy
        ? OnboardingConfig.privacyPolicyText
        : OnboardingConfig.termsOfServiceText;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: AmenColors.night,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AmenColors.mutedText.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                isPrivacy
                    ? Icons.privacy_tip_outlined
                    : Icons.description_outlined,
                color: AmenColors.amenGold,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: AmenColors.pureWhite,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AmenColors.nightElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AmenColors.blueMist.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              content.trim(),
              style: textTheme.bodyMedium?.copyWith(
                color: AmenColors.pureWhite.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
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
                l10n.close,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
