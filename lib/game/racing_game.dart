import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../screens/game_over_screen.dart';
import '../screens/hud.dart';
import '../screens/start_screen.dart';
import '../services/score_storage.dart';
import 'components/background.dart';
import 'components/coin.dart';
import 'components/enemy_car.dart';
import 'components/player_car.dart';
import 'components/road.dart';
import 'components/scenery.dart';
import 'components/speed_effects.dart';
import 'perspective.dart';
import 'track.dart';

/// The main game: owns the 3D camera, the track, everything on the road,
/// spawning, scoring and game state.
class RacingGame extends FlameGame with TapCallbacks, DragCallbacks {
  RacingGame({required this.storage, required this.bestScore});

  static const int laneCount = 3;

  /// Score needed to reach top speed.
  static const double maxDifficultyScore = 3000;

  // Speeds in world units per second.
  static const double idleSpeed = 3500;
  static const double startSpeed = 7000;
  static const double maxSpeed = 16000;

  /// Enemy cars drive at this fraction of our speed, so we catch up to them.
  static const double enemySpeedRatio = 0.35;

  final ScoreStorage storage;
  final Random random = Random();

  /// Values shown by the Flutter HUD.
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<int> coinsNotifier = ValueNotifier(0);

  int bestScore;
  bool isNewBest = false;
  bool isPlaying = false;
  bool isGameOver = false;

  final Perspective view = Perspective();
  final Track track = Track();
  final List<SceneryItem> scenery = [];
  final List<EnemyCar> enemies = [];
  final List<Coin> coins = [];

  late final PlayerCar player;
  late final SpeedEffects _effects;

  /// Current speed in world units per second.
  double speed = idleSpeed;

  /// How far the background has slid sideways because of curves.
  double skyOffset = 0;

  double _score = 0;
  double _enemyTimer = 0;
  double _coinTimer = 0;
  double _dragDistanceX = 0;
  double _nextSceneryZ = 0;
  double _crashShake = 0;

  /// 0.0 at the start, 1.0 at top speed.
  double get difficulty => (_score / maxDifficultyScore).clamp(0.0, 1.0);

  /// Current speed as a fraction of top speed (0..1).
  double get speedFactor => speed / maxSpeed;

  double get playerZ => view.cameraZ + Perspective.playerDistance;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onGameResize(Vector2 size) {
    // The camera must know the new size before the components rebuild
    // their gradients and shapes.
    view.resize(size.x, size.y);
    super.onGameResize(size);
  }

  @override
  Future<void> onLoad() async {
    player = PlayerCar();
    _effects = SpeedEffects();
    addAll([Background(), Road(), player, _effects]);
    _spawnScenery();
  }

  @override
  void update(double dt) {
    // Avoid huge jumps after a hiccup or when the tab was in the background.
    dt = min(dt, 1 / 30);

    _updateSpeed(dt);
    view.cameraZ += speed * dt;
    view.cameraX = player.x * 0.55; // camera follows the car part of the way

    final playerSegment = (playerZ / Perspective.segmentLength).floor();
    skyOffset += track.curveAt(playerSegment) * speedFactor * dt * 0.5;

    _spawnScenery();
    scenery.removeWhere((s) => s.z < view.cameraZ);

    // After a crash, cars brake together with us so the scene "freezes"
    // with the car we hit right in front.
    final enemySpeed = isGameOver ? speed : speed * enemySpeedRatio;
    for (final enemy in enemies) {
      enemy.z += enemySpeed * dt;
    }
    enemies.removeWhere((e) => e.z < playerZ - 800);

    for (final coin in coins) {
      coin.update(dt);
    }
    coins.removeWhere((c) => c.isRemoved || c.z < playerZ - 800);

    if (isPlaying) {
      _score += dt * 15;
      final shownScore = _score.floor();
      if (shownScore != scoreNotifier.value) scoreNotifier.value = shownScore;

      _enemyTimer -= dt;
      if (_enemyTimer <= 0) _spawnEnemies();

      _coinTimer -= dt;
      if (_coinTimer <= 0) _spawnCoins();

      _checkCollisions();
    }

    if (_crashShake > 0) _crashShake = max(0, _crashShake - dt * 1.8);

    super.update(dt);
  }

  void _updateSpeed(double dt) {
    final double target;
    if (isGameOver) {
      target = 0;
    } else if (isPlaying) {
      target = startSpeed + (maxSpeed - startSpeed) * difficulty;
    } else {
      target = idleSpeed;
    }
    if (speed < target) {
      speed = min(target, speed + 5000 * dt);
    } else {
      // Brake hard after a crash, ease off otherwise.
      speed = max(target, speed - (isGameOver ? 22000 : 6000) * dt);
    }
  }

  /// Wraps the whole scene in a small random offset for screen shake.
  @override
  void render(Canvas canvas) {
    var amount = _crashShake * 10;
    if (isPlaying) {
      amount += ((speedFactor - 0.7) / 0.3).clamp(0.0, 1.0) * 1.6;
    }
    if (amount < 0.05) {
      super.render(canvas);
      return;
    }
    canvas.save();
    canvas.translate(
      (random.nextDouble() * 2 - 1) * amount,
      (random.nextDouble() * 2 - 1) * amount,
    );
    super.render(canvas);
    canvas.restore();
  }

  void startGame() {
    enemies.clear();
    coins.clear();

    _score = 0;
    scoreNotifier.value = 0;
    coinsNotifier.value = 0;
    isNewBest = false;
    _enemyTimer = 1.2;
    _coinTimer = 0.5;
    _crashShake = 0;
    player.reset();

    isGameOver = false;
    isPlaying = true;

    overlays.remove(StartScreen.overlayName);
    overlays.remove(GameOverScreen.overlayName);
    overlays.add(Hud.overlayName);
  }

  void _gameOver(EnemyCar hitCar) {
    isPlaying = false;
    isGameOver = true;
    player.crash();
    _effects.flash();
    _crashShake = 1;
    // Keep the car we hit just in front of us instead of inside us.
    hitCar.z = max(hitCar.z, playerZ + 240);

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

  /// New cars and coins appear this far ahead (small, near the horizon).
  double get _spawnZ => view.cameraZ + Perspective.drawDistance * 0.6;

  bool _isLaneFree(int lane, double z, double range) {
    for (final enemy in enemies) {
      if (enemy.lane == lane && (enemy.z - z).abs() < range) return false;
    }
    for (final coin in coins) {
      if (coin.lane == lane && (coin.z - z).abs() < range) return false;
    }
    return true;
  }

  void _spawnEnemies() {
    final z = _spawnZ;
    final freeLanes = [
      for (var lane = 0; lane < laneCount; lane++)
        if (_isLaneFree(lane, z, 2600)) lane,
    ]..shuffle(random);

    if (freeLanes.isEmpty) {
      _enemyTimer = 0.2; // try again very soon
      return;
    }

    // Sometimes two cars side by side, but always leave one lane open.
    final twoCars =
        freeLanes.length >= 2 && random.nextDouble() < 0.1 + 0.3 * difficulty;
    final count = twoCars ? 2 : 1;
    for (var i = 0; i < count; i++) {
      enemies.add(EnemyCar(
        lane: freeLanes[i],
        z: z,
        color: EnemyCar.colors[random.nextInt(EnemyCar.colors.length)],
      ));
    }

    // Spawn more often as difficulty rises.
    final interval = 1.4 - 0.7 * difficulty;
    _enemyTimer = interval * (0.85 + random.nextDouble() * 0.3);
  }

  /// Spawns a short trail of coins in a lane with no cars ahead.
  void _spawnCoins() {
    final z = _spawnZ;
    // Coins are faster than cars (they don't move), so never put them in
    // a lane where a car is still ahead of us.
    final busyLanes = {
      for (final e in enemies)
        if (e.z > playerZ - 300) e.lane,
    };
    final lanes = [
      for (var lane = 0; lane < laneCount; lane++)
        if (!busyLanes.contains(lane) && _isLaneFree(lane, z, 3000)) lane,
    ];

    if (lanes.isNotEmpty) {
      final lane = lanes[random.nextInt(lanes.length)];
      final count = 3 + random.nextInt(3);
      for (var i = 0; i < count; i++) {
        coins.add(Coin(
          lane: lane,
          z: z - i * 550,
          spin: i * 0.4,
        ));
      }
    }
    _coinTimer = 1.6 + random.nextDouble() * 1.4;
  }

  /// Fills the roadside with trees, lamps, signs and curve chevrons.
  void _spawnScenery() {
    const segLen = Perspective.segmentLength;
    const rw = Perspective.roadHalfWidth;
    final limit = view.cameraZ + Perspective.drawDistance;

    while (_nextSceneryZ < limit) {
      final z = _nextSceneryZ;
      final segment = (z / segLen).floor();
      final curve = track.curveAt(segment);

      if (segment % 12 == 0) {
        // Street lamps on both sides with arms over the road.
        scenery.add(SceneryItem(
            type: SceneryType.lamp, x: -rw * 1.22, z: z, facing: 1));
        scenery.add(SceneryItem(
            type: SceneryType.lamp, x: rw * 1.22, z: z, facing: -1));
      } else if (curve.abs() > 0.5 && segment % 4 == 0) {
        // Chevrons on the outside of the bend, pointing into it.
        final side = curve > 0 ? -1.0 : 1.0;
        scenery.add(SceneryItem(
          type: SceneryType.chevron,
          x: side * rw * 1.25,
          z: z,
          facing: curve > 0 ? 1 : -1,
        ));
      } else if (segment % 41 == 7) {
        final side = random.nextBool() ? 1.0 : -1.0;
        scenery.add(SceneryItem(
          type: SceneryType.billboard,
          x: side * rw * 2.0,
          z: z,
          variant: random.nextInt(4),
        ));
      }

      // Trees and bushes, further out from the road.
      for (final side in const [-1.0, 1.0]) {
        if (random.nextDouble() < 0.24) {
          final roll = random.nextDouble();
          final type = roll < 0.45
              ? SceneryType.pine
              : roll < 0.8
                  ? SceneryType.roundTree
                  : SceneryType.bush;
          scenery.add(SceneryItem(
            type: type,
            x: side * rw * (1.6 + random.nextDouble() * 2.4),
            z: z + random.nextDouble() * segLen,
          ));
        }
      }

      _nextSceneryZ += segLen;
    }
  }

  // ---------------------------------------------------------------------------
  // Collisions (in world space, only near the player)
  // ---------------------------------------------------------------------------

  void _checkCollisions() {
    final pz = playerZ;
    final px = player.x;
    final carWidth = player.worldWidth;

    for (final enemy in enemies) {
      if ((enemy.z - pz).abs() < 230 &&
          (enemy.x - px).abs() < carWidth * 0.82) {
        _gameOver(enemy);
        return;
      }
    }

    for (final coin in coins) {
      if (coin.isCollected) continue;
      if ((coin.z - pz).abs() < 300 && (coin.x - px).abs() < carWidth * 0.85) {
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
