import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/haptic_service.dart';
import '../../../services/settings_service.dart';

/// Purple accent used for active toggle state (matches the user grid color).
const Color _activeColor = Color(0xFFB8A9D4); // soft purple from palette[0]
const Color _inactiveTrack = Color(0xFFD1D5DB);
const Color _inactiveThumb = Color(0xFF9CA3AF);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Header: back arrow + SETTINGS (matches home screen icon position) ──
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        HapticService.lightTap();
                        Navigator.of(context).pop();
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF111111),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontFamily: 'SourceSerif4',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Settings list ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: <Widget>[
                    // Section: General
                    const _SectionHeader(title: 'General'),
                    _SettingToggle(
                      title: 'Sound Effects',
                      subtitle: 'Play sounds on actions',
                      value: settings.soundEnabled,
                      onChanged: (_) => notifier.toggleSound(),
                    ),
                    _SettingToggle(
                      title: 'Haptic Feedback',
                      subtitle: 'Vibrate on interactions',
                      value: settings.hapticEnabled,
                      onChanged: (_) => notifier.toggleHaptic(),
                    ),

                    const SizedBox(height: 28),

                    // Section: Timer
                    const _SectionHeader(title: 'Timer'),
                    _SettingToggle(
                      title: 'Turn Timer',
                      subtitle: 'Limit time per move for both players',
                      value: settings.timerEnabled,
                      onChanged: (_) => notifier.toggleTimer(),
                    ),

                    // Timer duration picker (only when timer is enabled)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: settings.timerEnabled
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: _TimerDurationPicker(
                        seconds: settings.timerSeconds,
                        onIncrement: notifier.incrementTimer,
                        onDecrement: notifier.decrementTimer,
                      ),
                      secondChild: const SizedBox.shrink(),
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

// ── Section header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'SourceSerif4',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

// ── Toggle row (no icon) ──────────────────────────────────────────

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'SourceSerif4',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'SourceSerif4',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Large custom toggle
          GestureDetector(
            onTap: () {
              HapticService.lightTap();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: value ? _activeColor : _inactiveTrack,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? Colors.white : _inactiveThumb,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timer duration picker (fixed values: 5, 10, 30, 60) ──────────

class _TimerDurationPicker extends StatelessWidget {
  const _TimerDurationPicker({
    required this.seconds,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int seconds;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static const List<int> _values = <int>[5, 10, 30, 60];

  int get _currentIndex =>
      _values.indexOf(seconds).clamp(0, _values.length - 1);

  String get _label {
    if (seconds >= 60 && seconds % 60 == 0) {
      final int mins = seconds ~/ 60;
      return '$mins min';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final bool canDecrement = _currentIndex > 0;
    final bool canIncrement = _currentIndex < _values.length - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: <Widget>[
          const Text(
            'Time per turn',
            style: TextStyle(
              fontFamily: 'SourceSerif4',
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          // ── Stepper control ──
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _StepperButton(
                  icon: Icons.remove,
                  onTap: canDecrement ? onDecrement : null,
                ),
                Container(
                  width: 52,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _label,
                    style: const TextStyle(
                      fontFamily: 'SourceSerif4',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onTap: canIncrement ? onIncrement : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticService.lightTap();
              onTap!();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF111111) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}
