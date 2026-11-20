import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';
import 'car_painter.dart';

/// The player's car near the bottom of the screen. Moves one lane at a time.
class PlayerCar extends PositionComponent with HasGameReference<RacingGame> {
  PlayerCar() : super(anchor: Anchor.center, priority: 2);

  static const int startLane = 1;

  int lane = startLane;
  bool _crashed = false;
  double _crashTime = 0;

  @override
  Future<void> onLoad() async {
    _layout();
    position.x = game.laneCenterX(lane);
  }

  void reset() {
    lane = startLane;
    _crashed = false;
    _crashTime = 0;
    angle = 0;
    _layout();
    position.x = game.laneCenterX(lane);
  }

  void moveLeft() => lane = max(0, lane - 1);

  void moveRight() => lane = min(RacingGame.laneCount - 1, lane + 1);

  void crash() {
    _crashed = true;
    _crashTime = 0;
  }

  /// Slightly smaller than the drawing so near-misses feel fair.
  Rect get hitRect => Rect.fromCenter(
        center: position.toOffset(),
        width: size.x * 0.8,
        height: size.y * 0.88,
      );

  void _layout() {
    size = game.carSize;
    position.y = game.size.y - size.y * 0.75 - game.size.y * 0.05;
  }

  @override
  void update(double dt) {
    _layout();

    if (_crashed) {
      // Little spin-out wobble after a crash.
      _crashTime += dt;
      angle = sin(_crashTime * 30) * 0.25 * max(0, 1 - _crashTime * 2);
      return;
    }

    // Glide smoothly towards the target lane.
    final targetX = game.laneCenterX(lane);
    final t = min(1.0, dt * 14);
    position.x += (targetX - position.x) * t;

    // Lean a little while changing lanes.
    angle = ((targetX - position.x) / game.laneWidth) * 0.35;
  }

  @override
  void render(Canvas canvas) {
    paintCar(
      canvas,
      size.toSize(),
      bodyColor: const Color(0xFFE53935),
      stripeColor: const Color(0xFFFFFFFF),
    );
  }
}
