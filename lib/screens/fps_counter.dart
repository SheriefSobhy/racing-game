import 'package:flutter/material.dart';

import '../game/racing_game.dart';

/// Small frame-rate readout in the bottom-left corner.
/// Only shown when the page URL ends with ?debug.
class FpsCounter extends StatelessWidget {
  const FpsCounter({super.key, required this.game});

  static const overlayName = 'fps';

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: game.debugInfo,
              builder: (context, text, _) => Text(
                text.isEmpty ? '... FPS' : text,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
