import 'package:flutter/material.dart';

import '../../../services/sound_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
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
              padding: const EdgeInsets.only(bottom: 48),
              child: GestureDetector(
                onTap: () async {
                  await SoundService.playHomePlay();
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
    );
  }
}
