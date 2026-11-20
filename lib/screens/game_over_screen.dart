import 'package:flutter/material.dart';

import '../game/racing_game.dart';
import 'widgets.dart';

/// Shown after a crash: score, best score, coins and a Restart button.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key, required this.game});

  static const overlayName = 'gameOver';

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return ScreenBackdrop(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xEE1B263B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFF6D00), width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            if (game.isNewBest) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEW BEST!',
                  style: TextStyle(
                    color: Color(0xFF1B263B),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _StatRow(label: 'Score', value: game.scoreNotifier.value),
            _StatRow(label: 'Best', value: game.bestScore),
            _StatRow(label: 'Coins', value: game.coinsNotifier.value),
            const SizedBox(height: 28),
            BigButton(
              label: 'RESTART',
              icon: Icons.replay_rounded,
              onPressed: game.startGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
