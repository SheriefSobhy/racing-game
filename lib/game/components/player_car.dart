import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../perspective.dart';
import '../racing_game.dart';
import 'car_painter.dart';
import 'enemy_car.dart';

/// The player's car, seen from behind. It slides between lanes and tilts
/// a little while changing lanes.
class PlayerCar extends Component with HasGameReference<RacingGame> {
  PlayerCar() : super(priority: 2);

  static const int startLane = 1;
  static const Color bodyColor = Color(0xFFE53935);

  int lane = startLane;

  /// Current sideways position in world units (glides towards the lane).
  double x = Perspective.laneX(startLane);

  double _tilt = 0;
  double _time = 0;
  bool _crashed = false;
  double _crashTime = 0;

  void reset() {
    lane = startLane;
    x = Perspective.laneX(lane);
    _tilt = 0;
    _crashed = false;
    _crashTime = 0;
  }

  void moveLeft() => lane = max(0, lane - 1);

  void moveRight() => lane = min(RacingGame.laneCount - 1, lane + 1);

  void crash() {
    _crashed = true;
    _crashTime = 0;
  }

  /// Car width in world units, used for collisions.
  double get worldWidth => EnemyCar.worldWidth;

  @override
  void update(double dt) {
    _time += dt;
    if (_crashed) {
      _crashTime += dt;
      // Spin-out wobble that settles down.
      _tilt = sin(_crashTime * 28) * 0.22 * max(0.0, 1 - _crashTime * 1.5);
      return;
    }

    final targetX = Perspective.laneX(lane);
    final previousX = x;
    x += (targetX - x) * min(1.0, dt * 12);

    // Tilt (roll) towards the direction of travel while changing lanes.
    final lateralSpeed = dt > 0 ? (x - previousX) / dt : 0.0;
    final targetTilt = (lateralSpeed / 4000).clamp(-0.14, 0.14);
    _tilt += (targetTilt - _tilt) * min(1.0, dt * 14);
  }

  @override
  void render(Canvas canvas) {
    final view = game.view;
    final z = view.cameraZ + Perspective.playerDistance;
    final point = view.project(x, z);
    final pixelWidth = worldWidth * point.scale * 1.05;

    // A tiny bounce from the road surface, stronger at speed.
    final speedFactor = game.speedFactor;
    final bounce = _crashed
        ? 0.0
        : sin(_time * 38) * speedFactor * pixelWidth * 0.006 +
            sin(_time * 13) * pixelWidth * 0.004;

    canvas.save();
    canvas.translate(point.x, point.y + bounce);
    canvas.rotate(_tilt);
    canvas.scale(pixelWidth);
    CarPainter.paintCar(
      canvas,
      body: bodyColor,
      pixelWidth: pixelWidth,
      lean: (point.x - view.centerX) / view.width * 2 - _tilt * 2,
      isPlayer: true,
      boost: _crashed ? 0 : ((speedFactor - 0.45) / 0.55).clamp(0.0, 1.0),
      time: _time,
    );
    canvas.restore();
  }
}
