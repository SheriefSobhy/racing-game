import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';

/// A spinning gold coin lying on the road.
class Coin extends PositionComponent with HasGameReference<RacingGame> {
  Coin({required this.lane}) : super(anchor: Anchor.center, priority: 1);

  final int lane;
  bool isCollected = false;

  double _time = 0;
  double _collectTime = 0;

  static final _outer = Paint()..color = const Color(0xFFFFB300);
  static final _inner = Paint()..color = const Color(0xFFFFD54F);
  static final _ring = Paint()
    ..color = const Color(0xFFFF8F00)
    ..style = PaintingStyle.stroke;
  static final _shine = Paint()..color = const Color(0xCCFFFFFF);
  static final _shadow = Paint()..color = const Color(0x40000000);

  @override
  Future<void> onLoad() async {
    final r = game.coinRadius;
    size = Vector2.all(r * 2);
    position = Vector2(game.laneCenterX(lane), -r * 2);
    _time = game.random.nextDouble() * pi;
  }

  Rect get hitRect => Rect.fromCenter(
        center: position.toOffset(),
        width: size.x,
        height: size.y,
      );

  /// Starts a quick "pop" animation, then removes the coin.
  void collect() {
    isCollected = true;
  }

  @override
  void update(double dt) {
    _time += dt;
    final r = game.coinRadius;
    size = Vector2.all(r * 2);
    position.x = game.laneCenterX(lane);
    position.y += game.speed * dt;

    if (isCollected) {
      _collectTime += dt;
      if (_collectTime > 0.25) removeFromParent();
    }
    if (position.y > game.size.y + size.y) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final center = Offset(r, r);

    canvas.save();
    if (isCollected) {
      // Grow and fade out.
      final p = (_collectTime / 0.25).clamp(0.0, 1.0);
      canvas.translate(r, r);
      canvas.scale(1 + p);
      canvas.translate(-r, -r);
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - p));
    } else {
      canvas.drawOval(
        Rect.fromCenter(
            center: center.translate(r * 0.15, r * 0.25),
            width: r * 2,
            height: r * 1.6),
        _shadow,
      );
    }

    // Spin effect: squash horizontally.
    final spin = 0.35 + 0.65 * cos(_time * 4).abs();
    canvas.translate(r, r);
    canvas.scale(spin, 1);
    canvas.translate(-r, -r);

    canvas.drawCircle(center, r, _outer);
    canvas.drawCircle(center, r * 0.72, _inner);
    _ring.strokeWidth = r * 0.12;
    canvas.drawCircle(center, r * 0.72, _ring);
    // Little shine.
    canvas.drawOval(
      Rect.fromCenter(
          center: center.translate(-r * 0.3, -r * 0.35),
          width: r * 0.35,
          height: r * 0.22),
      _shine,
    );

    if (isCollected) canvas.restore(); // saveLayer
    canvas.restore();
  }
}
