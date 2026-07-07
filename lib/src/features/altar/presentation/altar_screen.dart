import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../shared/services/audio_service.dart';
import '../../library/data/library_repository.dart';
import '../../library/domain/prayer_reflection.dart';
import '../../profile/data/profile_settings_provider.dart';
import '../domain/altar_music_track.dart';
import '../data/altar_music_repository.dart';
import 'altar_music_player_service.dart';

class AltarScreen extends ConsumerStatefulWidget {
  const AltarScreen({super.key});

  @override
  ConsumerState<AltarScreen> createState() => _AltarScreenState();
}

class _AltarScreenState extends ConsumerState<AltarScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = normalizeCatalogLocale(
      ref.watch(appLocaleProvider).languageCode,
    );
    final categoriesAsync = ref.watch(
      publishedCatalogCategoriesProvider(locale),
    );
    final prayersAsync = ref.watch(
      publishedPrayerItemsProvider((
        locale: locale,
        categoryId: _selectedCategoryId,
        searchQuery: null,
      )),
    );

    return CustomScrollView(
      key: const PageStorageKey('altar-scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          sliver: SliverToBoxAdapter(
            child: categoriesAsync.when(
              loading: () => _AltarHeader(
                categories: const [],
                selectedCategoryId: _selectedCategoryId,
                isLoading: true,
                onCategorySelected: (categoryId) {
                  setState(() => _selectedCategoryId = categoryId);
                },
              ),
              error: (error, _) => _AltarHeader(
                categories: const [],
                selectedCategoryId: _selectedCategoryId,
                error: '$error',
                onCategorySelected: (categoryId) {
                  setState(() => _selectedCategoryId = categoryId);
                },
              ),
              data: (categories) => _AltarHeader(
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() => _selectedCategoryId = categoryId);
                },
              ),
            ),
          ),
        ),
        prayersAsync.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AmenColors.amenGold),
            ),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: _AltarStateMessage(
              icon: Icons.cloud_off_outlined,
              title: l10n.catalogUnavailable,
              message: '$error',
            ),
          ),
          data: (prayers) {
            if (prayers.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _AltarStateMessage(
                  icon: Icons.church_outlined,
                  title: l10n.noPrayersPublished,
                  message: l10n.noPrayersPublishedMessage,
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
              sliver: SliverList.separated(
                itemCount: prayers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final prayer = prayers[index];
                  return _AltarPrayerTile(
                    prayer: prayer,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TeleprompterPrayerScreen(prayer: prayer),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AltarHeader extends StatelessWidget {
  const _AltarHeader({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.isLoading = false,
    this.error,
  });

  final List<PrayerCatalogCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.altar, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(l10n.altarSubtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        const _AltarRadioPlayer(),
        const SizedBox(height: 24),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AltarCategoryCard(
                  title: l10n.allCategory,
                  description: isLoading ? l10n.loading : l10n.publishedPrayers,
                  selected: selectedCategoryId == null,
                  imageUrl: null,
                  onTap: () => onCategorySelected(null),
                );
              }
              final category = categories[index - 1];
              return _AltarCategoryCard(
                title: category.title,
                description: category.description,
                selected: selectedCategoryId == category.id,
                imageUrl: category.backgroundImageUrl,
                onTap: () => onCategorySelected(category.id),
              );
            },
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: AmenColors.danger)),
        ],
      ],
    );
  }
}

class _AltarCategoryCard extends StatelessWidget {
  const _AltarCategoryCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 166,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AmenColors.nightElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AmenColors.amenGold : AmenColors.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AmenColors.night.withValues(alpha: 0.38),
                        AmenColors.night.withValues(alpha: 0.86),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AmenColors.amenGold
                              : AmenColors.pureWhite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AmenColors.mutedText,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AltarPrayerTile extends StatelessWidget {
  const _AltarPrayerTile({required this.prayer, required this.onTap});

  final PrayerReflection prayer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 138,
          decoration: BoxDecoration(
            color: AmenColors.glass.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AmenColors.line.withValues(alpha: 0.68)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (prayer.backgroundImageUrl != null)
                Image.network(
                  prayer.backgroundImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AmenColors.night.withValues(alpha: 0.66),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AmenColors.amenGold.withValues(
                        alpha: 0.16,
                      ),
                      child: Text(prayer.timeOfDay.icon),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            prayer.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AmenColors.pureWhite,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${prayer.category} - ${prayer.readTimeMinutes} min',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      prayer.audioUrl == null
                          ? Icons.play_circle_outline_rounded
                          : Icons.graphic_eq_rounded,
                      color: AmenColors.amenGold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AltarStateMessage extends StatelessWidget {
  const _AltarStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AmenColors.amenGold, size: 42),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class TeleprompterPrayerScreen extends ConsumerStatefulWidget {
  const TeleprompterPrayerScreen({super.key, required this.prayer});

  final PrayerReflection prayer;

  @override
  ConsumerState<TeleprompterPrayerScreen> createState() =>
      _TeleprompterPrayerScreenState();
}

class _TeleprompterPrayerScreenState
    extends ConsumerState<TeleprompterPrayerScreen> {
  final _scrollController = ScrollController();
  Timer? _scrollTimer;
  var _isScrolling = true;
  var _speed = 0.42;
  var _prayerAudioEnabled = false;
  var _prayerAudioVolume = 0.32;

  @override
  void initState() {
    super.initState();
    _prayerAudioEnabled = widget.prayer.audioUrl != null;
    _startAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.prayer.audioUrl == null) return;
      ref
          .read(audioServiceProvider)
          .playPrayerAudio(widget.prayer.audioUrl!, volume: _prayerAudioVolume);
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    Future.microtask(() async {
      await ref.read(altarAmbientMixerProvider.notifier).stopAll();
      await ref.read(audioServiceProvider).stopPrayerAudio();
    });
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!_isScrolling || !_scrollController.hasClients) return;
      final nextOffset = _scrollController.offset + _speed;
      if (nextOffset >= _scrollController.position.maxScrollExtent) {
        setState(() => _isScrolling = false);
        return;
      }
      _scrollController.jumpTo(nextOffset);
    });
  }

  Future<void> _togglePrayerAudio() async {
    final url = widget.prayer.audioUrl;
    if (url == null) return;
    final enabled = !_prayerAudioEnabled;
    setState(() => _prayerAudioEnabled = enabled);
    if (enabled) {
      await ref
          .read(audioServiceProvider)
          .playPrayerAudio(url, volume: _prayerAudioVolume);
    } else {
      await ref.read(audioServiceProvider).stopPrayerAudio();
    }
  }

  Future<void> _setPrayerAudioVolume(double value) async {
    setState(() => _prayerAudioVolume = value);
    await ref.read(audioServiceProvider).setPrayerAudioVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AmenColors.night,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.prayer.backgroundImageUrl != null)
              Positioned.fill(
                child: Image.network(
                  widget.prayer.backgroundImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AmenColors.night.withValues(alpha: 0.76),
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.prayer.title,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AmenColors.amenGold,
                        fontWeight: FontWeight.w600,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.prayer.category} - ${widget.prayer.readTimeMinutes} min',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      widget.prayer.body.trim(),
                      style: textTheme.headlineMedium?.copyWith(
                        color: AmenColors.pureWhite,
                        fontWeight: FontWeight.w400,
                        height: 1.56,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.close,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() => _isScrolling = !_isScrolling);
                    },
                    icon: Icon(
                      _isScrolling
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    tooltip: _isScrolling ? l10n.pause : l10n.resume,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _TeleprompterControlPanel(
                speed: _speed,
                isScrolling: _isScrolling,
                prayerHasAudio: widget.prayer.audioUrl != null,
                prayerAudioEnabled: _prayerAudioEnabled,
                prayerAudioVolume: _prayerAudioVolume,
                onSpeedChanged: (value) => setState(() => _speed = value),
                onToggleScroll: () {
                  setState(() => _isScrolling = !_isScrolling);
                },
                onTogglePrayerAudio: _togglePrayerAudio,
                onPrayerAudioVolumeChanged: _setPrayerAudioVolume,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeleprompterControlPanel extends ConsumerWidget {
  const _TeleprompterControlPanel({
    required this.speed,
    required this.isScrolling,
    required this.prayerHasAudio,
    required this.prayerAudioEnabled,
    required this.prayerAudioVolume,
    required this.onSpeedChanged,
    required this.onToggleScroll,
    required this.onTogglePrayerAudio,
    required this.onPrayerAudioVolumeChanged,
  });

  final double speed;
  final bool isScrolling;
  final bool prayerHasAudio;
  final bool prayerAudioEnabled;
  final double prayerAudioVolume;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleScroll;
  final VoidCallback onTogglePrayerAudio;
  final ValueChanged<double> onPrayerAudioVolumeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixer = ref.watch(altarAmbientMixerProvider);
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AmenColors.deepSpace.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AmenColors.line.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AmenColors.night.withValues(alpha: 0.62),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton.filled(
                  onPressed: onToggleScroll,
                  icon: Icon(
                    isScrolling
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  tooltip: isScrolling ? l10n.pauseScroll : l10n.startScroll,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: speed,
                    min: 0.12,
                    max: 1.4,
                    activeColor: AmenColors.amenGold,
                    inactiveColor: AmenColors.line,
                    onChanged: onSpeedChanged,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.speed_rounded, color: AmenColors.amenGold),
              ],
            ),
            const SizedBox(height: 6),
            if (prayerHasAudio)
              _PrayerAudioControl(
                enabled: prayerAudioEnabled,
                volume: prayerAudioVolume,
                onToggle: onTogglePrayerAudio,
                onVolumeChanged: onPrayerAudioVolumeChanged,
              )
            else
              for (final track in AltarAmbientTrack.values)
                _AmbientTrackControl(track: track, mixer: mixer),
          ],
        ),
      ),
    );
  }
}

class _PrayerAudioControl extends StatelessWidget {
  const _PrayerAudioControl({
    required this.enabled,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  final bool enabled;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(
          value: enabled,
          activeThumbColor: AmenColors.amenGold,
          activeTrackColor: AmenColors.amenGold.withValues(alpha: 0.28),
          onChanged: (_) => onToggle(),
        ),
        SizedBox(
          width: 112,
          child: Text(
            'Prayer music',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: enabled ? AmenColors.pureWhite : AmenColors.mutedText,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: volume,
            activeColor: AmenColors.amenGold,
            inactiveColor: AmenColors.line,
            onChanged: enabled ? onVolumeChanged : null,
          ),
        ),
      ],
    );
  }
}

class _AmbientTrackControl extends ConsumerWidget {
  const _AmbientTrackControl({required this.track, required this.mixer});

  final AltarAmbientTrack track;
  final AltarAmbientMixerState mixer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = mixer.isEnabled(track);

    return Row(
      children: [
        Switch(
          value: enabled,
          activeThumbColor: AmenColors.amenGold,
          activeTrackColor: AmenColors.amenGold.withValues(alpha: 0.28),
          onChanged: (_) {
            ref.read(altarAmbientMixerProvider.notifier).toggleTrack(track);
          },
        ),
        SizedBox(
          width: 112,
          child: Text(
            track.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: enabled ? AmenColors.pureWhite : AmenColors.mutedText,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: mixer.volumeFor(track),
            activeColor: AmenColors.amenGold,
            inactiveColor: AmenColors.line,
            onChanged: enabled
                ? (value) => ref
                      .read(altarAmbientMixerProvider.notifier)
                      .setVolume(track, value)
                : null,
          ),
        ),
      ],
    );
  }
}

class _AltarRadioPlayer extends ConsumerWidget {
  const _AltarRadioPlayer();

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(altarMusicTracksProvider);
    final playerState = ref.watch(altarMusicPlayerProvider);

    return tracksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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

        return Container(
          decoration: BoxDecoration(
            color: AmenColors.nightElevated.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AmenColors.line.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _RotatingVinyl(isPlaying: playerState.isPlaying),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTrack.title,
                          style: const TextStyle(
                            color: AmenColors.pureWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentTrack.artist,
                          style: const TextStyle(
                            color: AmenColors.warmGold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_play_rounded, color: AmenColors.mutedText),
                    onPressed: () => _showPlaylistBottomSheet(context, tracks, playerState, ref),
                    tooltip: 'Playlist',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              Row(
                children: [
                  Text(
                    _formatDuration(playerState.position),
                    style: const TextStyle(color: AmenColors.mutedText, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AmenColors.amenGold,
                        inactiveTrackColor: AmenColors.line,
                        thumbColor: AmenColors.amenGold,
                      ),
                      child: Slider(
                        value: playerState.position.inMilliseconds.toDouble(),
                        max: playerState.duration.inMilliseconds.toDouble() > 0 
                            ? playerState.duration.inMilliseconds.toDouble() 
                            : 1.0,
                        onChanged: (value) {
                          ref.read(altarMusicPlayerProvider.notifier).seek(
                                Duration(milliseconds: value.toInt()),
                              );
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(playerState.duration),
                    style: const TextStyle(color: AmenColors.mutedText, fontSize: 11),
                  ),
                ],
              ),
              // Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: hasPrevious ? AmenColors.pureWhite : AmenColors.mutedText.withValues(alpha: 0.4),
                    iconSize: 32,
                    onPressed: hasPrevious 
                        ? () => ref.read(altarMusicPlayerProvider.notifier).skipToPrevious() 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  if (playerState.isLoading)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: AmenColors.amenGold,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        final notifier = ref.read(altarMusicPlayerProvider.notifier);
                        if (playerState.isPlaying) {
                          notifier.pause();
                        } else {
                          notifier.play();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AmenColors.amenGold,
                        ),
                        child: Icon(
                          playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AmenColors.night,
                          size: 32,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    color: hasNext ? AmenColors.pureWhite : AmenColors.mutedText.withValues(alpha: 0.4),
                    iconSize: 32,
                    onPressed: hasNext 
                        ? () => ref.read(altarMusicPlayerProvider.notifier).skipToNext() 
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistBottomSheet(
    BuildContext context,
    List<AltarMusicTrack> tracks,
    AltarMusicPlayerState playerState,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AmenColors.night,
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AmenColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Relaxing Altar Music',
                style: TextStyle(
                  color: AmenColors.pureWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Background & Lock Screen Playback Enabled',
                style: TextStyle(
                  color: AmenColors.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AmenColors.line, height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isCurrent = playerState.currentTrack?.id == track.id;
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent ? AmenColors.amenGold.withValues(alpha: 0.1) : AmenColors.nightElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrent && playerState.isPlaying 
                              ? Icons.volume_up_rounded 
                              : Icons.music_note_rounded,
                          color: isCurrent ? AmenColors.amenGold : AmenColors.mutedText,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(
                          color: isCurrent ? AmenColors.amenGold : AmenColors.pureWhite,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        track.artist,
                        style: const TextStyle(
                          color: AmenColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isCurrent && playerState.isPlaying 
                          ? const Text(
                              'Playing',
                              style: TextStyle(
                                color: AmenColors.amenGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : null,
                      onTap: () {
                        ref.read(altarMusicPlayerProvider.notifier).playTrackDirectly(tracks, track);
                        Navigator.of(context).pop();
                      },
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
}

class _RotatingVinyl extends StatefulWidget {
  const _RotatingVinyl({required this.isPlaying});
  final bool isPlaying;

  @override
  State<_RotatingVinyl> createState() => _RotatingVinylState();
}

class _RotatingVinylState extends State<_RotatingVinyl> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _RotatingVinyl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: AmenColors.line, width: 2),
          boxShadow: [
            BoxShadow(
              color: AmenColors.amenGold.withValues(alpha: widget.isPlaying ? 0.35 : 0.0),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl groove lines
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 1),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 1),
              ),
            ),
            // Center gold label
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AmenColors.amenGold,
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
