import 'package:vibration/vibration.dart';

/// Centralized haptic feedback using the vibration package.
///
/// All public methods are no-ops when haptics are disabled or the device
/// has no vibrator. Call [updateSettings] whenever the user preference changes.
class HapticService {
  HapticService._();

  static bool _enabled = true;
  static bool? _hasVibrator;

  static void updateSettings({required bool hapticEnabled}) {
    _enabled = hapticEnabled;
  }

  static Future<void> _ensureChecked() async {
    _hasVibrator ??= await Vibration.hasVibrator() ?? false;
  }

  static Future<bool> get _canVibrate async {
    await _ensureChecked();
    return _enabled && (_hasVibrator ?? false);
  }

  /// Soft tap — cell selection, toggle switch, navigation icon.
  static Future<void> lightTap() async {
    if (!await _canVibrate) return;
    Vibration.vibrate(duration: 20, amplitude: 40);
  }

  /// Slightly stronger tap — direction arrow chosen, button press.
  static Future<void> mediumTap() async {
    if (!await _canVibrate) return;
    Vibration.vibrate(duration: 35, amplitude: 80);
  }

  /// Firm tap — word submitted, game action.
  static Future<void> heavyTap() async {
    if (!await _canVibrate) return;
    Vibration.vibrate(duration: 50, amplitude: 128);
  }

  /// Double-pulse for success — word placed successfully.
  static Future<void> success() async {
    if (!await _canVibrate) return;
    Vibration.vibrate(
      pattern: <int>[0, 30, 60, 30],
      intensities: <int>[0, 100, 0, 180],
    );
  }

  /// Short buzz for error — invalid word, bad placement.
  static Future<void> error() async {
    if (!await _canVibrate) return;
    Vibration.vibrate(
      pattern: <int>[0, 40, 30, 40, 30, 40],
      intensities: <int>[0, 200, 0, 200, 0, 200],
    );
  }
}
