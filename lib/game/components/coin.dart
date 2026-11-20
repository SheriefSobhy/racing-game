import 'dart:math';
import 'dart:ui';

import '../perspective.dart';
import '../world_object.dart';

/// A spinning gold coin floating above the road.
///
/// Performance: no glows, no transparency layers; all paints and the star
/// shape are created once. Far-away coins are a single circle.
class Coin extends WorldObject {
  Coin({required this.lane, required super.z, required double spin})
      : _time = spin,
        super(x: Perspective.laneX(lane));

  /// Coin radius and float height in world units.
  static const double radius = 110;
  static const double floatHeight = 230;
  static const double _popDuration = 0.25;

  final int lane;
  bool isCollected = false;
  double _time;
  double _popTime = 0;

  static final Paint _shadow = Paint()..color = const Color(0x4D000000);
  static final Paint _rim = Paint()..color = const Color(0xFFB7791F);
  static final Paint _face = Paint()
    ..shader = Gradient.linear(
      const Offset(-1, -1),
      const Offset(1, 1),
      const [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFE08E00)],
      const [0.0, 0.45, 1.0],
    );
  static final Paint _simpleFace = Paint()..color = const Color(0xFFFFC107);
  static final Paint _inner = Paint()..color = const Color(0xFFFFCA28);
  static final Paint _ring = Paint()
    ..color = const Color(0xFFD48806)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;
  static final Paint _shine = Paint()..color = const Color(0xFFFFFDE7);
  static final Path _star = _buildStar();

  void collect() => isCollected = true;

  void update(double dt) {
    _time += dt;
    if (isCollected) {
      _popTime += dt;
      if (_popTime > _popDuration) isRemoved = true;
    }
  }

  @override
  void paint(Canvas canvas, ScreenPoint point, Perspective view) {
    final s = point.scale;
    final r = radius * s;
    if (r < 1) return;

    final bob = sin(_time * 5) * 0.12 + 1;
    var lift = floatHeight * s * bob;
    var size = r;
    if (isCollected) {
      // Quick pop: rise and shrink away (no transparency needed).
      final p = (_popTime / _popDuration).clamp(0.0, 1.0);
      lift += r * 3 * p;
      size = r * (1 + p * 0.4) * (1 - p);
      if (size < 0.5) return;
    }

    canvas.save();
    canvas.translate(point.x, point.y);

    if (r < 6) {
      // Far away: a plain gold dot.
      canvas.drawCircle(Offset(0, -lift - r), r, _simpleFace);
      canvas.restore();
      return;
    }

    if (!isCollected) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r * 0.4),
        _shadow,
      );
    }

    canvas.translate(0, -lift - r);
    canvas.scale(size);

    // Spin: squash horizontally; the rim shows as the coin turns.
    final turn = cos(_time * 4);
    final faceWidth = turn.abs().clamp(0.08, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0.06 * turn.sign, 0),
          width: faceWidth * 2 + 0.16,
          height: 2),
      _rim,
    );
    canvas.scale(faceWidth, 1);
    canvas.drawCircle(Offset.zero, 1, _face);
    canvas.drawCircle(Offset.zero, 0.72, _inner);
    canvas.drawCircle(Offset.zero, 0.72, _ring);
    canvas.drawPath(_star, _rim);
    canvas.drawOval(
        const Rect.fromLTRB(-0.55, -0.56, -0.15, -0.34), _shine);
    canvas.restore();
  }

  static Path _buildStar() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.42 : 0.18;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(cos(a) * r, sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }
}
