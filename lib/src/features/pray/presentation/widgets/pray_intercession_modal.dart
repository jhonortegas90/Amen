import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/amen_button_label.dart';
import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../../intentions/domain/intention.dart';
import '../../../library/data/library_repository.dart';

class PrayIntercessionModal extends ConsumerStatefulWidget {
  const PrayIntercessionModal({
    super.key,
    required this.intention,
    required this.onConfirm,
  });

  final Intention intention;
  final Future<void> Function() onConfirm;

  @override
  ConsumerState<PrayIntercessionModal> createState() => _PrayIntercessionModalState();
}

class _PrayIntercessionModalState extends ConsumerState<PrayIntercessionModal> {
  bool _isSubmitting = false;

  String _mapCategoryToCatalogId(PrayerCategory category) {
    switch (category) {
      case PrayerCategory.healing:
        return 'healing';
      case PrayerCategory.peace:
        return 'anxiety-peace';
      case PrayerCategory.strength:
        return 'strength';
      case PrayerCategory.grief:
        return 'anxiety-peace';
      case PrayerCategory.gratitude:
        return 'evening';
      case PrayerCategory.guidance:
        return 'morning';
      case PrayerCategory.general:
        return 'anytime';
    }
  }

  String _getFallbackPrayerBody(BuildContext context, PrayerCategory category) {
    final locale = Localizations.localeOf(context).languageCode;
    final fallbacks = {
      'en': {
        PrayerCategory.healing: "Lord, touch this person with Your healing hands. Restore their health, strengthen their body, and grant them peace.",
        PrayerCategory.peace: "Father, quiet their restless heart. Be their shelter in the storm, and let Your peace which surpasses understanding guard their mind.",
        PrayerCategory.strength: "Lord, be their fortress. Give them courage to face this trial, endurance to persist, and faith to know You are with them.",
        PrayerCategory.grief: "God of all comfort, wrap Your loving arms around them. Comfort them in their sorrow and remind them of the hope of Your eternal presence.",
        PrayerCategory.gratitude: "We thank You, Lord, for Your goodness and blessings. May their heart overflow with joy, recognizing Your hand in all things.",
        PrayerCategory.guidance: "Holy Spirit, lead them. Make their path clear, grant them discernment, and help them walk in Your truth with confidence.",
        PrayerCategory.general: "Lord, hear our prayers. Bless this request, meet every need according to Your riches, and make Your presence felt in their life.",
      },
      'es': {
        PrayerCategory.healing: "Señor, toca a esta persona con Tus manos sanadoras. Restaura su salud, fortalece su cuerpo y concédeles paz.",
        PrayerCategory.peace: "Padre, aquieta su corazón inquieto. Sé su refugio en la tormenta y deja que Tu paz, que sobrepasa todo entendimiento, guarde su mente.",
        PrayerCategory.strength: "Señor, sé su fortaleza. Dales valentía para enfrentar esta prueba, constancia para persistir y fe para saber que estás con ellos.",
        PrayerCategory.grief: "Dios de todo consuelo, rodéalos con Tus brazos amorosos. Consuélalos en su dolor y recuérdales la esperanza de Tu presencia eterna.",
        PrayerCategory.gratitude: "Te damos gracias, Señor, por Tu bondad y Tus bendiciones. Que su corazón rebose de gozo, reconociendo Tu mano en todas las cosas.",
        PrayerCategory.guidance: "Espíritu Santo, guíalos. Haz claro su camino, concédeles discernimiento y ayúdalos a caminar en Tu verdad con confianza.",
        PrayerCategory.general: "Señor, escucha nuestras oraciones. Bendice esta petición, suple cada necesidad conforme a Tus riquezas y haz sentir Tu presencia en su vida.",
      },
      'fr': {
        PrayerCategory.healing: "Seigneur, touche cette personne de Tes mains guérisseuses. Restaure sa santé, fortifie son corps et accorde-lui la paix.",
        PrayerCategory.peace: "Père, apaise leur cœur agité. Sois leur abri dans la tempête, et que Ta paix qui surpasse toute intelligence garde leur esprit.",
        PrayerCategory.strength: "Seigneur, sois leur forteresse. Donne-leur le courage de faire face à cette épreuve, l'endurance de persévérer et la foi de savoir que Tu es avec eux.",
        PrayerCategory.grief: "Dieu de toute consolation, entoure-les de Tes bras d'amour. Console-les dans leur douleur et rappelle-leur l'espérance de Ta présence éternelle.",
        PrayerCategory.gratitude: "Nous Te remercions, Seigneur, pour Ta bonté et Tes bénédictions. Que leur cœur déborde de joie, reconnaissant Ta main en toutes choses.",
        PrayerCategory.guidance: "Saint-Esprit, conduis-les. Rends leur chemin clair, accorde-leur le discernment et aide-les à marcher dans Ta vérité avec confiance.",
        PrayerCategory.general: "Seigneur, écoute nos prières. Bénis cette demande, réponds à chaque besoin selon Tes richesses et fais sentir Ta présence dans leur vie.",
      }
    };
    final langDict = fallbacks[locale] ?? fallbacks['en']!;
    return langDict[category] ?? langDict[PrayerCategory.general]!;
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    
    final catalogCategoryId = _mapCategoryToCatalogId(widget.intention.category);
    final prayersAsync = ref.watch(publishedPrayerItemsProvider((
      locale: locale,
      categoryId: catalogCategoryId,
      searchQuery: null,
    )));

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: AmenColors.night,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: AmenColors.amenGold.withValues(alpha: 0.35),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AmenColors.amenGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AmenColors.amenGold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AmenColors.amenGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.intercedingForRequest,
                      style: textTheme.titleMedium?.copyWith(
                        color: AmenColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.intention.category.icon} '
                      '${l10n.prayerCategory(widget.intention.category.displayName)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AmenColors.amenGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AmenColors.nightElevated.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AmenColors.line.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '“${widget.intention.text}”',
              style: textTheme.bodyMedium?.copyWith(
                color: AmenColors.text.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          prayersAsync.when(
            data: (prayers) {
              String title = l10n.aPrayerForIntention;
              String body = '';

              if (prayers.isNotEmpty) {
                final selectedIndex = widget.intention.id.hashCode % prayers.length;
                final reflection = prayers[selectedIndex];
                title = reflection.title;
                body = reflection.body;
              } else {
                body = _getFallbackPrayerBody(context, widget.intention.category);
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AmenColors.glass.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AmenColors.amenGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: AmenColors.amenGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AmenColors.text.withValues(alpha: 0.95),
                        height: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                  color: AmenColors.amenGold,
                ),
              ),
            ),
            error: (err, stack) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AmenColors.glass.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AmenColors.amenGold.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _getFallbackPrayerBody(context, widget.intention.category),
                style: textTheme.bodyLarge?.copyWith(
                  color: AmenColors.text.withValues(alpha: 0.95),
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AmenColors.amenGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.done_all_rounded,
                          size: 20,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: AmenButtonLabel(
                            l10n.iHavePrayedForYou,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
