import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/amen_colors.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../shared/presentation/animated_music_icon.dart';
import '../../../../shared/services/audio_service.dart';
import '../../../notifications/data/notifications_repository.dart';

class AmenTopBar extends ConsumerWidget {
  const AmenTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMuted = ref.watch(audioMutedNotifierProvider);

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/AppLogo.png',
                  width: 38,
                  height: 38,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.auto_awesome,
                    color: AmenColors.amenGold,
                    size: 30,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.goodAfternoon,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AmenColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.takeQuietMoment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AmenColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 92,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TopBarIconButton(
                    icon: Icons.graphic_eq_rounded,
                    iconChild: AnimatedMusicIcon(
                      color: isMuted
                          ? AmenColors.mutedText
                          : AmenColors.amenGold,
                      isMuted: isMuted,
                      size: 21,
                    ),
                    label: l10n.ambience,
                    selected: !isMuted,
                    onTap: () =>
                        ref.read(audioMutedNotifierProvider.notifier).toggle(),
                  ),
                  const SizedBox(width: 8),
                  _NotificationsButton(label: l10n.notifications),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsButton extends ConsumerWidget {
  const _NotificationsButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Builder(
          builder: (buttonContext) => _TopBarIconButton(
            icon: Icons.notifications_none_rounded,
            label: label,
            selected: unreadCount > 0,
            onTap: () {
              final renderBox = buttonContext.findRenderObject() as RenderBox?;
              Offset? buttonOffset;
              if (renderBox != null && renderBox.hasSize) {
                final pos = renderBox.localToGlobal(Offset.zero);
                final size = renderBox.size;
                buttonOffset = Offset(
                  pos.dx + size.width / 2,
                  pos.dy + size.height / 2,
                );
              }
              context.push('/notifications', extra: buttonOffset);
            },
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: AmenColors.amenGold,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconChild,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? iconChild;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AmenColors.amenGold.withValues(alpha: 0.58)
        : AmenColors.line.withValues(alpha: 0.62);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AmenColors.night.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child:
                iconChild ??
                Icon(
                  icon,
                  color: selected ? AmenColors.amenGold : AmenColors.mutedText,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}
