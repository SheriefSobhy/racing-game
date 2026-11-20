import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../screens/game_over_screen.dart';
import '../screens/hud.dart';
import '../screens/start_screen.dart';
import '../services/score_storage.dart';
import 'components/coin.dart';
import 'components/enemy_car.dart';
import 'components/player_car.dart';
import 'components/road.dart';

/// The main game: owns the road, the player, spawning, scoring and game state.
class RacingGame extends FlameGame with TapCallbacks, DragCallbacks {
  RacingGame({required this.storage, required this.bestScore});

  static const int laneCount = 3;

  /// Score needed to reach top speed.
  static const double maxDifficultyScore = 3000;

  final ScoreStorage storage;
  final Random random = Random();

  /// Values shown by the Flutter HUD.
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<int> coinsNotifier = ValueNotifier(0);

  int bestScore;
  bool isNewBest = false;
  bool isPlaying = false;
  bool isGameOver = false;

  late final PlayerCar player;

  double _score = 0;
  double _enemyTimer = 0;
  double _coinTimer = 0;
  double _dragDistanceX = 0;

  // ---------------------------------------------------------------------------
  // Layout helpers (everything scales with the screen size).
  // ---------------------------------------------------------------------------

  /// Width of the grass on each side of the road.
  double get roadLeft => size.x * 0.09;
  double get roadWidth => size.x - roadLeft * 2;
  double get laneWidth => roadWidth / laneCount;
  double laneCenterX(int lane) => roadLeft + laneWidth * (lane + 0.5);

  /// Car size based on lane width, but never too tall on wide screens.
  Vector2 get carSize {
    var width = laneWidth * 0.56;
    var height = width * 1.8;
    final maxHeight = size.y * 0.14;
    if (height > maxHeight) {
      height = maxHeight;
      width = height / 1.8;
    }
    return Vector2(width, height);
  }

  double get coinRadius => min(laneWidth * 0.17, size.y * 0.03);

  /// 0.0 at the start, 1.0 at top speed.
  double get difficulty => (_score / maxDifficultyScore).clamp(0.0, 1.0);

  /// Road speed in pixels per second (relative to screen height).
  double get speed {
    if (isGameOver) return 0;
    if (!isPlaying) return size.y * 0.35; // gentle scrolling on start screen
    return size.y * (0.6 + 0.9 * difficulty);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    add(Road());
    player = PlayerCar();
    add(player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying) return;

    _score += dt * 15;
    final shownScore = _score.floor();
    if (shownScore != scoreNotifier.value) scoreNotifier.value = shownScore;

    _enemyTimer -= dt;
    if (_enemyTimer <= 0) _spawnEnemies();

    _coinTimer -= dt;
    if (_coinTimer <= 0) _spawnCoin();

    _checkCollisions();
  }

  void startGame() {
    for (final enemy in children.whereType<EnemyCar>()) {
      enemy.removeFromParent();
    }
    for (final coin in children.whereType<Coin>()) {
      coin.removeFromParent();
    }

    _score = 0;
    scoreNotifier.value = 0;
    coinsNotifier.value = 0;
    isNewBest = false;
    _enemyTimer = 1.0;
    _coinTimer = 0.6;
    player.reset();

    isGameOver = false;
    isPlaying = true;

    overlays.remove(StartScreen.overlayName);
    overlays.remove(GameOverScreen.overlayName);
    overlays.add(Hud.overlayName);
  }

  void _gameOver() {
    isPlaying = false;
    isGameOver = true;
    player.crash();

    final finalScore = scoreNotifier.value;
    if (finalScore > bestScore) {
      bestScore = finalScore;
      isNewBest = true;
      storage.saveBestScore(bestScore);
    }

    overlays.remove(Hud.overlayName);
    overlays.add(GameOverScreen.overlayName);
  }

  // ---------------------------------------------------------------------------
  // Spawning
  // ---------------------------------------------------------------------------

  /// A lane is free at the top if nothing was spawned there recently.
  bool _isLaneFreeAtTop(int lane) {
    final limit = carSize.y * 1.6;
    for (final enemy in children.whereType<EnemyCar>()) {
      if (enemy.lane == lane && enemy.position.y < limit) return false;
    }
    for (final coin in children.whereType<Coin>()) {
      if (coin.lane == lane && coin.position.y < limit) return false;
    }
    return true;
  }

  void _spawnEnemies() {
    final freeLanes = [
      for (var lane = 0; lane < laneCount; lane++)
        if (_isLaneFreeAtTop(lane)) lane,
    ]..shuffle(random);

    if (freeLanes.isEmpty) {
      _enemyTimer = 0.2; // try again very soon
      return;
    }

    // Sometimes spawn two cars side by side, but always leave one lane open.
    final twoCars =
        freeLanes.length >= 2 && random.nextDouble() < 0.1 + 0.3 * difficulty;
    final count = twoCars ? 2 : 1;
    for (var i = 0; i < count; i++) {
      add(EnemyCar(lane: freeLanes[i]));
    }

    // Spawn faster as difficulty rises.
    final interval = 1.3 - 0.6 * difficulty;
    _enemyTimer = interval * (0.85 + random.nextDouble() * 0.3);
  }

  void _spawnCoin() {
    // Coins move faster than enemies, so avoid lanes with any enemy on screen.
    final enemyLanes =
        children.whereType<EnemyCar>().map((e) => e.lane).toSet();
    final lanes = [
      for (var lane = 0; lane < laneCount; lane++)
        if (!enemyLanes.contains(lane) && _isLaneFreeAtTop(lane)) lane,
    ];

    if (lanes.isNotEmpty) {
      add(Coin(lane: lanes[random.nextInt(lanes.length)]));
    }
    _coinTimer = 0.7 + random.nextDouble() * 0.8;
  }

  // ---------------------------------------------------------------------------
  // Collisions
  // ---------------------------------------------------------------------------

  void _checkCollisions() {
    final playerRect = player.hitRect;

    for (final enemy in children.whereType<EnemyCar>()) {
      if (enemy.hitRect.overlaps(playerRect)) {
        _gameOver();
        return;
      }
    }

    for (final coin in children.whereType<Coin>()) {
      if (coin.isCollected) continue;
      if (coin.hitRect.overlaps(playerRect)) {
        coin.collect();
        coinsNotifier.value++;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Input: tap the left/right half of the screen, or swipe.
  // ---------------------------------------------------------------------------

  @override
  void onTapUp(TapUpEvent event) {
    if (!isPlaying) return;
    if (event.localPosition.x < size.x / 2) {
      player.moveLeft();
    } else {
      player.moveRight();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragDistanceX = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _dragDistanceX += event.localDelta.x;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!isPlaying) return;
    final minSwipe = size.x * 0.06;
    if (_dragDistanceX <= -minSwipe || event.velocity.x < -300) {
      player.moveLeft();
    } else if (_dragDistanceX >= minSwipe || event.velocity.x > 300) {
      player.moveRight();
    }
  }
}
