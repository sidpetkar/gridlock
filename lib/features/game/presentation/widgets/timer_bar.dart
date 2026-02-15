import 'package:flutter/material.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : (remaining / total).clamp(0, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Turn time: ${remaining}s',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          color: const Color(0xFF111111),
          backgroundColor: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }
}
