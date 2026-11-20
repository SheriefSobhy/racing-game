import 'package:flutter/material.dart';

import '../game/racing_game.dart';
import 'widgets.dart';

/// First screen: title, best score and a Play button.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.game});

  static const overlayName = 'start';

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return ScreenBackdrop(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_filled,
              size: 72, color: Color(0xFFFFD54F)),
          const SizedBox(height: 8),
          const Text(
            'LANE RUSH',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: Color(0xFFFF6D00), blurRadius: 16)],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Best: ${game.bestScore}',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          BigButton(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            onPressed: game.startGame,
          ),
          const SizedBox(height: 32),
          const Text(
            'Tap left or right (or swipe) to change lanes.\n'
            'Dodge the cars and grab the coins!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}
