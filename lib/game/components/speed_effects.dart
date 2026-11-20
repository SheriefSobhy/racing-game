import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';

/// Speed lines rushing out from the horizon, a soft vignette, and a red
/// flash when crashing.
class SpeedEffects extends Component with HasGameReference<RacingGame> {
  SpeedEffects() : super(priority: 3);

  static const int _lineCount = 26;

  final _random = Random();
  final List<_Streak> _streaks = [];
  final Path _linePath = Path();
  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _vignettePaint = Paint();
  final Paint _flashPaint = Paint();

  double _flash = 0;

  void flash() => _flash = 1;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _vignettePaint.shader = Gradient.radial(
      Offset(size.x / 2, size.y * 0.55),
      max(size.x, size.y) * 0.75,
      const [Color(0x00000000), Color(0x00000000), Color(0x66000000)],
      const [0.0, 0.6, 1.0],
    );
    _linePaint.strokeWidth = max(1.5, size.x * 0.005);
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < _lineCount; i++) {
      _streaks.add(_Streak()..reset(_random, scatter: true));
    }
  }

  @override
  void update(double dt) {
    if (_flash > 0) _flash = max(0, _flash - dt * 2.5);
    final speed = game.speedFactor;
    for (final s in _streaks) {
      s.distance += dt * (0.6 + speed * 2.4) * (0.4 + s.distance);
      if (s.distance > 1.4) s.reset(_random);
    }
  }

  @override
  void render(Canvas canvas) {
    final view = game.view;
    final w = view.width;
    final h = view.height;

    // Speed lines appear above about 45% of top speed.
    final strength = ((game.speedFactor - 0.45) / 0.55).clamp(0.0, 1.0);
    if (strength > 0 && game.isPlaying) {
      final vx = view.centerX;
      final vy = view.horizonY;
      final reach = sqrt(w * w + h * h) * 0.75;
      _linePath.reset();
      for (final s in _streaks) {
        final start = s.distance * reach;
        final end = start + reach * (0.06 + 0.12 * strength) * s.distance;
        _linePath
          ..moveTo(vx + s.dx * start, vy + s.dy * start)
          ..lineTo(vx + s.dx * end, vy + s.dy * end);
      }
      _linePaint.color = Color.fromRGBO(255, 255, 255, 0.35 * strength);
      canvas.drawPath(_linePath, _linePaint);
    }

    canvas.drawRect(Rect.fromLTRB(-30, -30, w + 30, h + 30), _vignettePaint);

    if (_flash > 0) {
      _flashPaint.color = Color.fromRGBO(255, 60, 40, 0.45 * _flash);
      canvas.drawRect(Rect.fromLTRB(-30, -30, w + 30, h + 30), _flashPaint);
    }
  }
}

/// One speed line: a direction from the horizon and how far out it is.
class _Streak {
  double dx = 0;
  double dy = 0;
  double distance = 0;

  void reset(Random random, {bool scatter = false}) {
    // Mostly sideways and downwards, away from the sky's centre.
    final angle = random.nextBool()
        ? -0.35 + random.nextDouble() * 1.5 // right side
        : pi + 0.35 - random.nextDouble() * 1.5; // left side
    dx = cos(angle);
    dy = sin(angle);
    distance = scatter ? 0.35 + random.nextDouble() : 0.35;
  }
}
