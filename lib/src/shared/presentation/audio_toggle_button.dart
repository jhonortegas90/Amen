import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/amen_colors.dart';
import '../services/audio_service.dart';

class AudioToggleButton extends ConsumerWidget {
  const AudioToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(audioMutedNotifierProvider);

    return InkWell(
      onTap: () => ref.read(audioMutedNotifierProvider.notifier).toggle(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AmenColors.nightElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMuted
                ? AmenColors.mutedText.withValues(alpha: 0.3)
                : AmenColors.amenGold.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: isMuted ? AmenColors.mutedText : AmenColors.amenGold,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isMuted ? 'Muted' : 'Ambience',
              style: TextStyle(
                fontSize: 12,
                color: isMuted ? AmenColors.mutedText : AmenColors.amenGold,
                fontWeight: isMuted ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
