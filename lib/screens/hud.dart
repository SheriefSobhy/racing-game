import 'package:flutter/material.dart';

import '../game/racing_game.dart';

/// Score and coin counters shown at the top while playing.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  static const overlayName = 'hud';

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    // IgnorePointer so taps still reach the game underneath.
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Counter(
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFF80D8FF),
                notifier: game.scoreNotifier,
              ),
              _Counter(
                icon: Icons.monetization_on_rounded,
                iconColor: const Color(0xFFFFD54F),
                notifier: game.coinsNotifier,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.iconColor,
    required this.notifier,
  });

  final IconData icon;
  final Color iconColor;
  final ValueNotifier<int> notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (context, value, _) => Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
