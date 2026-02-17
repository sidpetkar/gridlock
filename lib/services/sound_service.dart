import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();

  static bool _soundEnabled = true;

  static void updateSettings({required bool soundEnabled}) {
    _soundEnabled = soundEnabled;
  }

  /// Play the home-screen "Play" button sound.
  static Future<void> playHomePlay() async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/gridlock-play.mp3'));
    } catch (e) {
      debugPrint('SoundService error (playHomePlay): $e');
    }
  }

  /// Play the gameplay button sound (Home / Skip / Restart).
  static Future<void> playButtonTap() async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/home-skip-restart.mp3'));
    } catch (e) {
      debugPrint('SoundService error (playButtonTap): $e');
    }
  }
}
