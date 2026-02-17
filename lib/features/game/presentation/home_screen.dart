import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/haptic_service.dart';
import '../../../services/sound_service.dart';
import '../application/game_controller.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              // ── Header: Leaderboard (left) · Settings (right) ──
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      // TODO: navigate to leaderboard
                    },
                    child: const Icon(
                      Icons.leaderboard_outlined,
                      color: Color(0xFF111111),
                      size: 24,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          pageBuilder: (_, __, ___) => const SettingsScreen(),
                          transitionDuration:
                              const Duration(milliseconds: 250),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF111111),
                      size: 24,
                    ),
                  ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Image.asset(
                  'gridlock-icon-2.png',
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GestureDetector(
                  onTap: () async {
                    HapticService.mediumTap();
                    await SoundService.playHomePlay();
                    // Always start a fresh game when tapping Play.
                    ref.read(gameControllerProvider.notifier).resetGame();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder<void>(
                        pageBuilder: (_, __, ___) => const GameScreen(),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                  child: Text(
                    'Play',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF111111),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
