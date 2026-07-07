import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../shared/services/audio_service.dart';
import '../../notifications/data/notification_service.dart';
import '../domain/altar_music_track.dart';

class AltarMusicPlayerState {
  const AltarMusicPlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playlist = const [],
    this.isLoading = false,
    this.currentIndex,
    this.volume = 1.0,
  });

  final AltarMusicTrack? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<AltarMusicTrack> playlist;
  final bool isLoading;
  final int? currentIndex;
  final double volume;

  AltarMusicPlayerState copyWith({
    AltarMusicTrack? Function()? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<AltarMusicTrack>? playlist,
    bool? isLoading,
    int? Function()? currentIndex,
    double? volume,
  }) {
    return AltarMusicPlayerState(
      currentTrack: currentTrack != null ? currentTrack() : this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playlist: playlist ?? this.playlist,
      isLoading: isLoading ?? this.isLoading,
      currentIndex: currentIndex != null ? currentIndex() : this.currentIndex,
      volume: volume ?? this.volume,
    );
  }
}

class AltarMusicPlayerNotifier extends Notifier<AltarMusicPlayerState> {
  late final AudioPlayer _player;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _indexSub;
  StreamSubscription? _volumeSub;

  @override
  AltarMusicPlayerState build() {
    _player = AudioPlayer();
    _initAudioSession();
    _listenToPlayerStreams();

    ref.onDispose(() {
      _positionSub?.cancel();
      _durationSub?.cancel();
      _playerStateSub?.cancel();
      _indexSub?.cancel();
      _volumeSub?.cancel();
      _player.dispose();
    });

    return const AltarMusicPlayerState();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  void _listenToPlayerStreams() {
    _positionSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      state = state.copyWith(
        isPlaying: isPlaying,
        isLoading:
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering,
      );
    });

    _indexSub = _player.currentIndexStream.listen((idx) {
      if (idx != null && idx < state.playlist.length) {
        state = state.copyWith(
          currentIndex: () => idx,
          currentTrack: () => state.playlist[idx],
        );
      } else {
        state = state.copyWith(
          currentIndex: () => null,
          currentTrack: () => null,
        );
      }
    });

    _volumeSub = _player.volumeStream.listen((vol) {
      state = state.copyWith(volume: vol);
    });
  }

  Future<void> setPlaylist(
    List<AltarMusicTrack> tracks, {
    int initialIndex = 0,
  }) async {
    if (tracks.isEmpty) return;

    // Convert to audio sources with background tags
    final audioSources = tracks.map((track) {
      final uri = Uri.parse(
        track.audioUrl.isNotEmpty
            ? track.audioUrl
            : 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ); // Fallback

      return AudioSource.uri(
        uri,
        tag: MediaItem(
          id: track.id,
          album: "Altar Radio",
          title: track.title,
          artist: track.artist,
          artUri: Uri.parse(AltarMusicTrack.defaultArtUrl),
        ),
      );
    }).toList();

    state = state.copyWith(
      playlist: tracks,
      currentIndex: () => initialIndex,
      currentTrack: () => tracks[initialIndex],
      position: Duration.zero,
      duration: Duration.zero,
    );

    try {
      await _player.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );
    } catch (_) {
      // Fallback gracefully on loading errors
    }
  }

  Future<void> play() async {
    try {
      // Request notification permission for lock screen controls
      await ref
          .read(notificationServiceProvider)
          .requestAuthorizationPermission();
    } catch (_) {}
    try {
      // Pause home music and stop ambient tracks to prevent overlap
      await ref.read(audioServiceProvider).pauseAmbient();
      await ref.read(altarAmbientMixerProvider.notifier).stopAll();
      await _player.play();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  Future<void> skipToNext() async {
    try {
      if (_player.hasNext) {
        await _player.seekToNext();
      }
    } catch (_) {}
  }

  Future<void> skipToPrevious() async {
    try {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      }
    } catch (_) {}
  }

  Future<void> playTrack(AltarMusicTrack track) async {
    final idx = state.playlist.indexWhere((t) => t.id == track.id);
    if (idx != -1) {
      await _player.seek(Duration.zero, index: idx);
      await play();
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } catch (_) {}
  }

  Future<void> skipNext() => skipToNext();
  Future<void> skipPrevious() => skipToPrevious();

  Future<void> playTrackDirectly(
    List<AltarMusicTrack> allTracks,
    AltarMusicTrack track,
  ) async {
    final idx = allTracks.indexWhere((t) => t.id == track.id);
    if (idx != -1) {
      await setPlaylist(allTracks, initialIndex: idx);
      await play();
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      state = state.copyWith(
        currentTrack: () => null,
        currentIndex: () => null,
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      );
    } catch (_) {}
  }
}

final altarMusicPlayerProvider =
    NotifierProvider<AltarMusicPlayerNotifier, AltarMusicPlayerState>(
      AltarMusicPlayerNotifier.new,
    );
