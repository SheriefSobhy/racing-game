import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/racing_game.dart';
import 'screens/fps_counter.dart';
import 'screens/game_over_screen.dart';
import 'screens/hud.dart';
import 'screens/start_screen.dart';
import 'services/score_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Browsers don't allow locking orientation, so only do it in the app.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final storage = ScoreStorage();
  final bestScore = await storage.loadBestScore();

  runApp(RacingApp(storage: storage, bestScore: bestScore));
}

class RacingApp extends StatefulWidget {
  const RacingApp({super.key, required this.storage, required this.bestScore});

  final ScoreStorage storage;
  final int bestScore;

  @override
  State<RacingApp> createState() => _RacingAppState();
}

class _RacingAppState extends State<RacingApp> {
  late final RacingGame _game = RacingGame(
    storage: widget.storage,
    bestScore: widget.bestScore,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lane Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        // On wide screens (desktop browser, landscape) keep a phone-shaped
        // portrait play area in the middle instead of stretching the road.
        body: LayoutBuilder(
          builder: (context, constraints) {
            const maxAspect = 0.65; // width / height
            final width = constraints.maxWidth / constraints.maxHeight > maxAspect
                ? constraints.maxHeight * maxAspect
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: GameWidget<RacingGame>(
                  game: _game,
                  initialActiveOverlays: [
                    StartScreen.overlayName,
                    if (_game.showFps) FpsCounter.overlayName,
                  ],
                  overlayBuilderMap: {
                    FpsCounter.overlayName: (context, game) =>
                        FpsCounter(game: game),
                    StartScreen.overlayName: (context, game) =>
                        StartScreen(game: game),
                    Hud.overlayName: (context, game) => Hud(game: game),
                    GameOverScreen.overlayName: (context, game) =>
                        GameOverScreen(game: game),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
