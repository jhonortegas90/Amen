import 'package:flutter/material.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';

class SponsoredPause extends StatelessWidget {
  const SponsoredPause({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.sponsoredPause,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AmenColors.ink.withValues(alpha: 0.62),
          border: Border.all(color: AmenColors.line.withValues(alpha: 0.62)),
        ),
        child: Row(
          children: [
            const Icon(Icons.spa_outlined, color: AmenColors.blueMist),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.sponsoredPause,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Text(
              'AD',
              style: TextStyle(
                color: AmenColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
