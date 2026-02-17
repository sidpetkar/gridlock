import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/game/presentation/home_screen.dart';
import 'services/haptic_service.dart';
import 'services/settings_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync services with settings whenever they change.
    final SettingsState settings = ref.watch(settingsProvider);
    SoundService.updateSettings(soundEnabled: settings.soundEnabled);
    HapticService.updateSettings(hapticEnabled: settings.hapticEnabled);

    return MaterialApp(
      title: 'Gridlock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
