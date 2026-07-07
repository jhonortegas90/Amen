import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_colors.dart';
import '../domain/altar_music_track.dart';
import '../data/altar_music_repository.dart';
import 'altar_music_player_service.dart';

class AltarMusicPlayerScreen extends ConsumerStatefulWidget {
  const AltarMusicPlayerScreen({super.key});

  @override
  ConsumerState<AltarMusicPlayerScreen> createState() => _AltarMusicPlayerScreenState();
}

class _AltarMusicPlayerScreenState extends ConsumerState<AltarMusicPlayerScreen> {
  bool _isVolumeMuted = false;
  double _preMuteVolume = 0.5;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showPlaylistDrawer(BuildContext context, List<AltarMusicTrack> tracks, AltarMusicPlayerState playerState) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AmenColors.nightElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AmenColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Altar Playlist Queue',
                style: TextStyle(
                  color: AmenColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AmenColors.line, height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: tracks.length,
                  separatorBuilder: (_, _) => const Divider(color: AmenColors.line, height: 1),
                  itemBuilder: (context, idx) {
                    final track = tracks[idx];
                    final isCurrent = playerState.currentTrack?.id == track.id;
                    return ListTile(
                      onTap: () {
                        ref.read(altarMusicPlayerProvider.notifier).playTrack(track);
                        Navigator.of(context).pop();
                      },
                      leading: Icon(
                        isCurrent ? Icons.play_circle_fill_rounded : Icons.music_note_rounded,
                        color: isCurrent ? AmenColors.amenGold : AmenColors.mutedText,
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(
                          color: isCurrent ? AmenColors.amenGold : AmenColors.pureWhite,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        track.artist,
                        style: const TextStyle(color: AmenColors.mutedText, fontSize: 12),
                      ),
                      trailing: track.id == 'default_serenity'
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AmenColors.amenGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: AmenColors.amenGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(altarMusicTracksProvider);
    final playerState = ref.watch(altarMusicPlayerProvider);

    return Scaffold(
      backgroundColor: AmenColors.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Blurred background of the track's artwork (if data loaded)
          tracksAsync.maybeWhen(
            data: (allTracks) {
              final artworkUrl = AltarMusicTrack.defaultArtUrl;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    artworkUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: AmenColors.night),
                  ),
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              );
            },
            orElse: () => Container(color: AmenColors.night),
          ),

          // 2. Main content overlay
          SafeArea(
            child: Column(
              children: [
                // Header Bar (ALWAYS visible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AmenColors.pureWhite, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Altar Radio',
                        style: TextStyle(
                          color: AmenColors.pureWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to balance back button
                    ],
                  ),
                ),

                // Body content area
                Expanded(
                  child: tracksAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AmenColors.amenGold),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AmenColors.danger,
                              size: 54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to load altar music',
                              style: TextStyle(
                                color: AmenColors.pureWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$error',
                              style: TextStyle(
                                color: AmenColors.pureWhite.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (allTracks) {
                      var tracks = allTracks.where((t) => t.isActive).toList();
                      if (tracks.isEmpty) {
                        tracks = AltarMusicTrack.demoTracks;
                      }

                      // Auto initialize playlist if empty
                      if (playerState.playlist.isEmpty) {
                        Future.microtask(() {
                          ref.read(altarMusicPlayerProvider.notifier).setPlaylist(tracks);
                        });
                      }

                      final currentTrack = playerState.currentTrack ?? tracks.first;
                      final hasPrevious = (playerState.currentIndex ?? 0) > 0;
                      final hasNext = (playerState.currentIndex ?? 0) < tracks.length - 1;

                      final artworkUrl = AltarMusicTrack.defaultArtUrl;

                      return Column(
                        children: [
                          const Spacer(),

                          // Artwork Card (Scales 1.0 when playing, 0.85 when paused)
                          AnimatedScale(
                            scale: playerState.isPlaying ? 1.0 : 0.86,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.76,
                              height: MediaQuery.of(context).size.width * 0.76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                  if (playerState.isPlaying)
                                    BoxShadow(
                                      color: AmenColors.amenGold.withValues(alpha: 0.22),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                    ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      artworkUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Center(
                                        child: Icon(Icons.music_note_rounded, color: AmenColors.amenGold, size: 80),
                                      ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.2),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Track details row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentTrack.title,
                                        style: const TextStyle(
                                          color: AmenColors.pureWhite,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        currentTrack.artist,
                                        style: TextStyle(
                                          color: AmenColors.pureWhite.withValues(alpha: 0.65),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite_border_rounded, color: AmenColors.pureWhite, size: 24),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Interactive Scrub Bar / Slider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: AmenColors.amenGold,
                                    inactiveTrackColor: AmenColors.pureWhite.withValues(alpha: 0.15),
                                    thumbColor: AmenColors.pureWhite,
                                    trackHeight: 3.5,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  ),
                                  child: Slider(
                                    value: playerState.position.inMilliseconds.toDouble().clamp(
                                          0.0,
                                          playerState.duration.inMilliseconds.toDouble(),
                                        ),
                                    max: playerState.duration.inMilliseconds.toDouble() == 0.0
                                        ? 1.0
                                        : playerState.duration.inMilliseconds.toDouble(),
                                    onChanged: (val) {
                                      ref.read(altarMusicPlayerProvider.notifier).seek(Duration(milliseconds: val.toInt()));
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(playerState.position),
                                        style: TextStyle(
                                          color: AmenColors.pureWhite.withValues(alpha: 0.5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(playerState.duration - playerState.position),
                                        style: TextStyle(
                                          color: AmenColors.pureWhite.withValues(alpha: 0.5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Playback Navigation Control Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded, size: 48),
                                  color: hasPrevious ? AmenColors.pureWhite : AmenColors.pureWhite.withValues(alpha: 0.3),
                                  onPressed: hasPrevious
                                      ? () => ref.read(altarMusicPlayerProvider.notifier).skipPrevious()
                                      : null,
                                ),
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AmenColors.pureWhite,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: playerState.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(22),
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : IconButton(
                                          icon: Icon(
                                            playerState.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 42,
                                            color: Colors.black,
                                          ),
                                          onPressed: () {
                                            final notifier = ref.read(altarMusicPlayerProvider.notifier);
                                            if (playerState.isPlaying) {
                                              notifier.pause();
                                            } else {
                                              notifier.play();
                                            }
                                          },
                                        ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, size: 48),
                                  color: hasNext ? AmenColors.pureWhite : AmenColors.pureWhite.withValues(alpha: 0.3),
                                  onPressed: hasNext
                                      ? () => ref.read(altarMusicPlayerProvider.notifier).skipNext()
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Volume Slider Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isVolumeMuted ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                                    color: AmenColors.pureWhite.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    final notifier = ref.read(altarMusicPlayerProvider.notifier);
                                    if (_isVolumeMuted) {
                                      notifier.setVolume(_preMuteVolume);
                                      setState(() => _isVolumeMuted = false);
                                    } else {
                                      _preMuteVolume = playerState.volume;
                                      notifier.setVolume(0.0);
                                      setState(() => _isVolumeMuted = true);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AmenColors.pureWhite,
                                      inactiveTrackColor: AmenColors.pureWhite.withValues(alpha: 0.15),
                                      thumbColor: AmenColors.pureWhite,
                                      trackHeight: 3.0,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                    ),
                                    child: Slider(
                                      value: _isVolumeMuted ? 0.0 : playerState.volume,
                                      onChanged: (val) {
                                        ref.read(altarMusicPlayerProvider.notifier).setVolume(val);
                                        if (val > 0.0) {
                                          setState(() => _isVolumeMuted = false);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: AmenColors.pureWhite.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Bottom Utility Bar (Queue)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.transparent),
                                  onPressed: null,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.queue_music_rounded,
                                    color: AmenColors.pureWhite.withValues(alpha: 0.7),
                                  ),
                                  onPressed: () => _showPlaylistDrawer(context, tracks, playerState),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.transparent),
                                  onPressed: null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
