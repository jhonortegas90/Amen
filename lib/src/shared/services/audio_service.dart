import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AltarAmbientTrack {
  worshipLofi('Worship Lo-Fi', 'audio/HomeMusic.mp3'),
  piano('Piano', 'audio/HomeMusic.mp3'),
  rain('Rain', 'audio/HomeMusic.mp3');

  const AltarAmbientTrack(this.label, this.assetPath);

  final String label;
  final String assetPath;
}

class AltarAmbientMixerState {
  const AltarAmbientMixerState({
    this.enabledTracks = const <AltarAmbientTrack, bool>{},
    this.volumes = const <AltarAmbientTrack, double>{},
  });

  final Map<AltarAmbientTrack, bool> enabledTracks;
  final Map<AltarAmbientTrack, double> volumes;

  bool isEnabled(AltarAmbientTrack track) => enabledTracks[track] ?? false;

  double volumeFor(AltarAmbientTrack track) => volumes[track] ?? 0.28;

  AltarAmbientMixerState copyWith({
    Map<AltarAmbientTrack, bool>? enabledTracks,
    Map<AltarAmbientTrack, double>? volumes,
  }) {
    return AltarAmbientMixerState(
      enabledTracks: enabledTracks ?? this.enabledTracks,
      volumes: volumes ?? this.volumes,
    );
  }
}

class AudioService with WidgetsBindingObserver {
  AudioService() {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  static const _mutedKey = 'ambient_audio_muted';
  static const _volumeKey = 'ambient_audio_volume';

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _prayerAudioPlayer = AudioPlayer();
  final Map<AltarAmbientTrack, AudioPlayer> _altarPlayers = {
    for (final track in AltarAmbientTrack.values) track: AudioPlayer(),
  };

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  double _volume = 0.34;
  double get volume => _volume;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool(_mutedKey) ?? false;
    _volume = prefs.getDouble(_volumeKey) ?? 0.34;

    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    await _ambientPlayer.setVolume(_isMuted ? 0.0 : _volume);
    await _prayerAudioPlayer.setReleaseMode(ReleaseMode.loop);
    await _prayerAudioPlayer.setVolume(0);
    for (final player in _altarPlayers.values) {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0);
    }

    await playHomeMusic();
  }

  Future<void> playHomeMusic() async {
    try {
      if (_ambientPlayer.state != PlayerState.playing) {
        await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
        await _ambientPlayer.setVolume(_isMuted ? 0.0 : _volume);
        await _ambientPlayer.play(AssetSource('audio/HomeMusic.mp3'));
        _isPlaying = true;
      }
    } catch (_) {
      // Fallback gracefully if audio playback cannot start immediately
    }
  }

  Future<void> pauseAmbient() async {
    try {
      await _ambientPlayer.pause();
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> resumeAmbient() async {
    try {
      if (_ambientPlayer.state != PlayerState.playing) {
        await _ambientPlayer.setVolume(_isMuted ? 0.0 : _volume);
        if (_ambientPlayer.state == PlayerState.paused) {
          await _ambientPlayer.resume();
        } else {
          await playHomeMusic();
        }
        _isPlaying = true;
      }
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
    if (!_isMuted) {
      await _ambientPlayer.setVolume(_volume);
    }
  }

  Future<void> toggleAmbient() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _isMuted);

    await _ambientPlayer.setVolume(_isMuted ? 0.0 : _volume);
    if (!_isMuted && _ambientPlayer.state != PlayerState.playing) {
      await resumeAmbient();
    }
  }

  Future<void> playAmenChime() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.4);
      await _sfxPlayer.play(AssetSource('audio/amen_chime.wav'));
    } catch (_) {
      // Fallback gracefully
    }
  }

  Future<void> setAltarTrackEnabled(
    AltarAmbientTrack track, {
    required bool enabled,
    required double volume,
  }) async {
    final player = _altarPlayers[track];
    if (player == null) return;

    try {
      if (enabled) {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(volume.clamp(0.0, 1.0));
        if (player.state != PlayerState.playing) {
          await player.play(AssetSource(track.assetPath));
        }
      } else {
        await player.stop();
      }
    } catch (_) {
      // Altar ambience is optional and should never interrupt prayer reading.
    }
  }

  Future<void> setAltarTrackVolume(
    AltarAmbientTrack track,
    double volume,
  ) async {
    final player = _altarPlayers[track];
    if (player == null) return;

    try {
      await player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> stopAltarMixer() async {
    for (final player in _altarPlayers.values) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  Future<void> playPrayerAudio(String url, {required double volume}) async {
    try {
      await _prayerAudioPlayer.stop();
      await _prayerAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _prayerAudioPlayer.setVolume(volume.clamp(0.0, 1.0));
      await _prayerAudioPlayer.play(UrlSource(url));
    } catch (_) {
      // Prayer-specific audio is optional; the text should remain available.
    }
  }

  Future<void> setPrayerAudioVolume(double volume) async {
    try {
      await _prayerAudioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> stopPrayerAudio() async {
    try {
      await _prayerAudioPlayer.stop();
    } catch (_) {}
  }

  // Track states for resume when app is minimized
  bool _wasAmbientPlaying = false;
  bool _wasPrayerPlaying = false;
  final Map<AltarAmbientTrack, bool> _wasAltarTrackPlaying = {};

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppPaused() {
    try {
      if (_ambientPlayer.state == PlayerState.playing) {
        _wasAmbientPlaying = true;
        _ambientPlayer.pause();
      } else {
        _wasAmbientPlaying = false;
      }

      if (_prayerAudioPlayer.state == PlayerState.playing) {
        _wasPrayerPlaying = true;
        _prayerAudioPlayer.pause();
      } else {
        _wasPrayerPlaying = false;
      }

      for (final entry in _altarPlayers.entries) {
        final track = entry.key;
        final player = entry.value;
        if (player.state == PlayerState.playing) {
          _wasAltarTrackPlaying[track] = true;
          player.pause();
        } else {
          _wasAltarTrackPlaying[track] = false;
        }
      }
    } catch (_) {}
  }

  void _onAppResumed() {
    try {
      if (_wasAmbientPlaying) {
        _ambientPlayer.resume();
      }

      if (_wasPrayerPlaying) {
        _prayerAudioPlayer.resume();
      }

      for (final entry in _altarPlayers.entries) {
        final track = entry.key;
        final player = entry.value;
        if (_wasAltarTrackPlaying[track] == true) {
          player.resume();
        }
      }
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambientPlayer.dispose();
    _sfxPlayer.dispose();
    _prayerAudioPlayer.dispose();
    for (final player in _altarPlayers.values) {
      player.dispose();
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioMutedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(audioServiceProvider).isMuted;
  }

  Future<void> toggle() async {
    final service = ref.read(audioServiceProvider);
    await service.toggleAmbient();
    state = service.isMuted;
  }
}

final audioMutedNotifierProvider = NotifierProvider<AudioMutedNotifier, bool>(
  AudioMutedNotifier.new,
);

class AudioVolumeNotifier extends Notifier<double> {
  @override
  double build() {
    return ref.watch(audioServiceProvider).volume;
  }

  Future<void> setVolume(double volume) async {
    final service = ref.read(audioServiceProvider);
    await service.setVolume(volume);
    state = service.volume;
  }
}

final audioVolumeNotifierProvider =
    NotifierProvider<AudioVolumeNotifier, double>(AudioVolumeNotifier.new);

class AltarAmbientMixerNotifier extends Notifier<AltarAmbientMixerState> {
  @override
  AltarAmbientMixerState build() {
    return AltarAmbientMixerState(
      enabledTracks: {
        for (final track in AltarAmbientTrack.values) track: false,
      },
      volumes: {for (final track in AltarAmbientTrack.values) track: 0.28},
    );
  }

  Future<void> toggleTrack(AltarAmbientTrack track) async {
    final nextEnabled = !state.isEnabled(track);
    final nextEnabledTracks = Map<AltarAmbientTrack, bool>.from(
      state.enabledTracks,
    )..[track] = nextEnabled;
    state = state.copyWith(enabledTracks: nextEnabledTracks);

    await ref
        .read(audioServiceProvider)
        .setAltarTrackEnabled(
          track,
          enabled: nextEnabled,
          volume: state.volumeFor(track),
        );
  }

  Future<void> setVolume(AltarAmbientTrack track, double volume) async {
    final nextVolumes = Map<AltarAmbientTrack, double>.from(state.volumes)
      ..[track] = volume.clamp(0.0, 1.0);
    state = state.copyWith(volumes: nextVolumes);

    if (state.isEnabled(track)) {
      await ref.read(audioServiceProvider).setAltarTrackVolume(track, volume);
    }
  }

  Future<void> stopAll() async {
    state = state.copyWith(
      enabledTracks: {
        for (final track in AltarAmbientTrack.values) track: false,
      },
    );
    await ref.read(audioServiceProvider).stopAltarMixer();
  }
}

final altarAmbientMixerProvider =
    NotifierProvider<AltarAmbientMixerNotifier, AltarAmbientMixerState>(
      AltarAmbientMixerNotifier.new,
    );
