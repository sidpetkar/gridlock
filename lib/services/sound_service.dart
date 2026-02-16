import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();

  /// Play the home-screen "Play" button sound + light haptic.
  static Future<void> playHomePlay() async {
    await HapticFeedback.lightImpact();
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/gridlock-play.mp3'));
    } catch (e) {
      debugPrint('SoundService error (playHomePlay): $e');
    }
  }

  /// Play the gameplay button sound (Home / Skip / Restart) + light haptic.
  static Future<void> playButtonTap() async {
    await HapticFeedback.lightImpact();
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/home-skip-restart.mp3'));
    } catch (e) {
      debugPrint('SoundService error (playButtonTap): $e');
    }
  }
}
