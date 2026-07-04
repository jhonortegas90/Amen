import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService() {
    _init();
  }

  static const _mutedKey = 'ambient_audio_muted';

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool(_mutedKey) ?? false;

    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    await _ambientPlayer.setVolume(_isMuted ? 0.0 : 0.18);
  }

  Future<void> toggleAmbient() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _isMuted);

    await _ambientPlayer.setVolume(_isMuted ? 0.0 : 0.18);
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

  void dispose() {
    _ambientPlayer.dispose();
    _sfxPlayer.dispose();
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
