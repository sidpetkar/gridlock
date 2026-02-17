import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.timerEnabled = false,
    this.timerSeconds = 30,
  });

  final bool soundEnabled;
  final bool hapticEnabled;
  final bool timerEnabled;
  final int timerSeconds;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? timerEnabled,
    int? timerSeconds,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          soundEnabled == other.soundEnabled &&
          hapticEnabled == other.hapticEnabled &&
          timerEnabled == other.timerEnabled &&
          timerSeconds == other.timerSeconds;

  @override
  int get hashCode => Object.hash(soundEnabled, hapticEnabled, timerEnabled, timerSeconds);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  static const List<int> timerPresets = <int>[5, 10, 30, 60];

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
  }

  void toggleTimer() {
    state = state.copyWith(timerEnabled: !state.timerEnabled);
  }

  void setTimerSeconds(int seconds) {
    state = state.copyWith(timerSeconds: seconds);
  }

  void incrementTimer() {
    final int idx = timerPresets.indexOf(state.timerSeconds);
    if (idx < 0) {
      state = state.copyWith(timerSeconds: timerPresets.first);
    } else if (idx < timerPresets.length - 1) {
      state = state.copyWith(timerSeconds: timerPresets[idx + 1]);
    }
  }

  void decrementTimer() {
    final int idx = timerPresets.indexOf(state.timerSeconds);
    if (idx < 0) {
      state = state.copyWith(timerSeconds: timerPresets.first);
    } else if (idx > 0) {
      state = state.copyWith(timerSeconds: timerPresets[idx - 1]);
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
