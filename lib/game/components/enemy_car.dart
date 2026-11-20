import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';
import 'car_painter.dart';

/// A slower car in one of the lanes. Hitting it ends the game.
class EnemyCar extends PositionComponent with HasGameReference<RacingGame> {
  EnemyCar({required this.lane}) : super(anchor: Anchor.center, priority: 1);

  /// Body / stripe colour pairs to pick from.
  static const _palettes = [
    (Color(0xFF1E88E5), Color(0xFFBBDEFB)), // blue
    (Color(0xFFFDD835), Color(0xFF212121)), // yellow
    (Color(0xFF8E24AA), Color(0xFFE1BEE7)), // purple
    (Color(0xFFFB8C00), Color(0xFFFFFFFF)), // orange
    (Color(0xFF00ACC1), Color(0xFF004D40)), // teal
    (Color(0xFFEC407A), Color(0xFFFFFFFF)), // pink
    (Color(0xFFECEFF1), Color(0xFF1565C0)), // white
  ];

  final int lane;
  late final Color _body;
  late final Color _stripe;

  @override
  Future<void> onLoad() async {
    final palette = _palettes[game.random.nextInt(_palettes.length)];
    _body = palette.$1;
    _stripe = palette.$2;
    size = game.carSize;
    position = Vector2(game.laneCenterX(lane), -size.y);
  }

  /// Slightly smaller than the drawing so near-misses feel fair.
  Rect get hitRect => Rect.fromCenter(
        center: position.toOffset(),
        width: size.x * 0.8,
        height: size.y * 0.88,
      );

  @override
  void update(double dt) {
    size = game.carSize;
    position.x = game.laneCenterX(lane);
    // Enemies drive forward too, just slower than us, so they come closer.
    position.y += game.speed * 0.6 * dt;
    if (position.y > game.size.y + size.y) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paintCar(canvas, size.toSize(), bodyColor: _body, stripeColor: _stripe);
  }
}
