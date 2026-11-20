import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';

/// Sky, sun, clouds, mountains and a city skyline above the horizon.
/// Each layer slides sideways at its own speed on curves (parallax).
/// All shapes are built once per screen size and reused every frame.
class Background extends Component with HasGameReference<RacingGame> {
  Background() : super(priority: 0);

  final Paint _skyPaint = Paint();
  final Paint _sunGlowPaint = Paint();
  final Paint _sunPaint = Paint();
  final Paint _farMountainPaint = Paint();
  final Paint _snowPaint = Paint()..color = const Color(0xB3F3EEF7);
  final Paint _hillPaint = Paint();
  final Paint _cityPaint = Paint();
  final Paint _windowPaint = Paint()..color = const Color(0xCCFFD180);
  final Paint _beaconPaint = Paint()..color = const Color(0xFFFF5252);
  final Paint _cloudPaint = Paint();
  final Paint _cloudShadePaint = Paint()..color = const Color(0x66B79AC4);

  _Layer? _farMountains;
  _Layer? _snowCaps;
  _Layer? _hills;
  _Layer? _city;
  _Layer? _windows;
  _Layer? _beacons;
  _Layer? _clouds;
  _Layer? _cloudShades;

  double _cloudDrift = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final w = size.x;
    final h = size.y;
    final horizon = game.view.horizonY;

    _skyPaint.shader = Gradient.linear(
      Offset.zero,
      Offset(0, horizon),
      const [
        Color(0xFF14204A),
        Color(0xFF34509A),
        Color(0xFF8E7DBE),
        Color(0xFFF2A88A),
        Color(0xFFFFD3A1),
      ],
      const [0.0, 0.35, 0.68, 0.9, 1.0],
    );

    final sunRadius = h * 0.045;
    _sunGlowPaint.shader = Gradient.radial(
      Offset.zero,
      sunRadius * 4,
      const [Color(0x88FFE0B2), Color(0x33FFAB91), Color(0x00FFAB91)],
      const [0.0, 0.4, 1.0],
    );
    _sunPaint.shader = Gradient.linear(
      Offset(0, -sunRadius),
      Offset(0, sunRadius),
      const [Color(0xFFFFF3C4), Color(0xFFFF9E6B)],
    );

    _cloudPaint.shader = Gradient.linear(
      Offset(0, horizon * 0.1),
      Offset(0, horizon * 0.75),
      const [Color(0xCCF4EEFF), Color(0xB3FFD9C7)],
    );

    final random = Random(42);
    final period = w * 1.6;

    _farMountainPaint.shader = Gradient.linear(
      Offset(0, horizon - h * 0.16),
      Offset(0, horizon),
      const [Color(0xFF7B7FB5), Color(0xFFB7A6C9)],
    );
    _hillPaint.shader = Gradient.linear(
      Offset(0, horizon - h * 0.08),
      Offset(0, horizon),
      const [Color(0xFF4F6A8F), Color(0xFF8E97B3)],
    );
    _cityPaint.shader = Gradient.linear(
      Offset(0, horizon - h * 0.1),
      Offset(0, horizon),
      const [Color(0xFF2A3157), Color(0xFF4A4F78)],
    );

    final far = _ridge(random, period, horizon, h * 0.15, h * 0.05, 7);
    _farMountains = _Layer(far.$1, period, 0.06);
    _snowCaps = _Layer(far.$2, period, 0.06);
    _hills = _Layer(_ridge(random, period, horizon, h * 0.075, h * 0.03, 11).$1,
        period, 0.13);

    final city = _skyline(random, period, horizon, w, h);
    _city = _Layer(city.$1, period, 0.24);
    _windows = _Layer(city.$2, period, 0.24);
    _beacons = _Layer(city.$3, period, 0.24);

    final clouds = _cloudShapes(random, period, horizon, h);
    _clouds = _Layer(clouds.$1, period, 0.03);
    _cloudShades = _Layer(clouds.$2, period, 0.03);
  }

  @override
  void update(double dt) {
    _cloudDrift += dt * 60; // clouds slowly drift even on straights
  }

  @override
  void render(Canvas canvas) {
    final view = game.view;
    final w = view.width;
    final horizon = view.horizonY;
    final offset = game.skyOffset * w;

    canvas.drawRect(Rect.fromLTRB(-30, -30, w + 30, horizon + 2), _skyPaint);

    // Sun, low over the mountains.
    final sunX = w * 0.68 - offset * 0.02;
    final sunY = horizon - view.height * 0.085;
    final sunRadius = view.height * 0.045;
    canvas.save();
    canvas.translate(sunX, sunY);
    canvas.drawCircle(Offset.zero, sunRadius * 4, _sunGlowPaint);
    canvas.drawCircle(Offset.zero, sunRadius, _sunPaint);
    canvas.restore();

    // Cloud undersides first, then the bright tops over them.
    _cloudShades?.draw(canvas, offset + _cloudDrift, w, _cloudShadePaint);
    _clouds?.draw(canvas, offset + _cloudDrift, w, _cloudPaint);
    _farMountains?.draw(canvas, offset, w, _farMountainPaint);
    _snowCaps?.draw(canvas, offset, w, _snowPaint);
    _hills?.draw(canvas, offset, w, _hillPaint);
    _city?.draw(canvas, offset, w, _cityPaint);
    _windows?.draw(canvas, offset, w, _windowPaint);
    _beacons?.draw(canvas, offset, w, _beaconPaint);
  }

  // ---------------------------------------------------------------------------
  // Shape builders. Every shape repeats seamlessly every [period] pixels.
  // ---------------------------------------------------------------------------

  /// A mountain ridge made of a few sine waves, plus its snow caps.
  (Path, Path) _ridge(Random random, double period, double horizon,
      double maxHeight, double minHeight, int peaks) {
    final waves = [
      for (final k in [peaks, peaks * 2 + 1, peaks * 4 + 3])
        (k, random.nextDouble() * pi * 2),
    ];
    const steps = 160;
    final heights = <double>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * pi * 2;
      var v = 0.0;
      v += sin(t * waves[0].$1 + waves[0].$2) * 0.6;
      v += sin(t * waves[1].$1 + waves[1].$2) * 0.28;
      v += sin(t * waves[2].$1 + waves[2].$2) * 0.12;
      final n = (v + 1) / 2; // 0..1
      heights.add(minHeight + (maxHeight - minHeight) * n * n);
    }

    final ridge = Path()..moveTo(0, horizon + 2);
    for (var i = 0; i <= steps; i++) {
      ridge.lineTo(period * i / steps, horizon - heights[i]);
    }
    ridge
      ..lineTo(period, horizon + 2)
      ..close();

    // Snow on the tallest parts.
    final snowLine = minHeight + (maxHeight - minHeight) * 0.72;
    final snow = Path();
    for (var i = 0; i < steps; i++) {
      final h1 = heights[i];
      final h2 = heights[i + 1];
      if (h1 > snowLine && h2 > snowLine) {
        final x1 = period * i / steps;
        final x2 = period * (i + 1) / steps;
        final drop1 = (h1 - snowLine) * 0.5;
        final drop2 = (h2 - snowLine) * 0.5;
        snow
          ..moveTo(x1, horizon - h1)
          ..lineTo(x2, horizon - h2)
          ..lineTo(x2, horizon - h2 + drop2)
          ..lineTo(x1, horizon - h1 + drop1)
          ..close();
      }
    }
    return (ridge, snow);
  }

  /// City buildings, lit windows and red beacons on the tallest towers.
  (Path, Path, Path) _skyline(
      Random random, double period, double horizon, double w, double h) {
    final buildings = Path();
    final windows = Path();
    final beacons = Path();

    // The city only covers part of the horizon.
    final cityStart = period * 0.15;
    final cityEnd = period * 0.65;
    var x = cityStart;
    while (x < cityEnd) {
      final bw = w * (0.025 + random.nextDouble() * 0.04);
      final centre = 1 - ((x - cityStart) / (cityEnd - cityStart) - 0.5).abs() * 2;
      final bh = h * (0.02 + random.nextDouble() * 0.05 + centre * 0.05);
      final rect = Rect.fromLTRB(x, horizon - bh, x + bw, horizon + 2);
      buildings.addRect(rect);

      // Window grid, some lit.
      final win = max(1.2, w * 0.004);
      for (var wy = rect.top + win * 2; wy < horizon - win * 2; wy += win * 2.4) {
        for (var wx = x + win; wx < x + bw - win * 1.5; wx += win * 2.2) {
          if (random.nextDouble() < 0.45) {
            windows.addRect(Rect.fromLTWH(wx, wy, win, win));
          }
        }
      }

      if (bh > h * 0.08) {
        buildings.addRect(Rect.fromLTWH(
            x + bw / 2 - 0.75, rect.top - h * 0.015, 1.5, h * 0.015));
        beacons.addOval(Rect.fromCircle(
            center: Offset(x + bw / 2, rect.top - h * 0.015), radius: 1.6));
      }
      x += bw + w * random.nextDouble() * 0.006;
    }
    return (buildings, windows, beacons);
  }

  /// A few soft clouds built from overlapping ovals.
  (Path, Path) _cloudShapes(
      Random random, double period, double horizon, double h) {
    final clouds = Path();
    final shades = Path();
    for (var i = 0; i < 5; i++) {
      final cx = period * (i + random.nextDouble() * 0.6) / 5;
      final cy = horizon * (0.18 + random.nextDouble() * 0.5);
      final size = h * (0.025 + random.nextDouble() * 0.02);
      for (var j = 0; j < 4; j++) {
        final ox = (j - 1.5) * size * 1.1;
        final oy = (j.isEven ? 0 : -size * 0.35);
        clouds.addOval(Rect.fromCenter(
            center: Offset(cx + ox, cy + oy),
            width: size * 2.2,
            height: size * 1.3));
      }
      // Slightly lower, darker copy that peeks out underneath.
      for (var j = 0; j < 4; j++) {
        final ox = (j - 1.5) * size * 1.1;
        final oy = (j.isEven ? 0 : -size * 0.35) + size * 0.22;
        shades.addOval(Rect.fromCenter(
            center: Offset(cx + ox + size * 0.1, cy + oy),
            width: size * 2.2,
            height: size * 1.3));
      }
    }
    return (clouds, shades);
  }
}

/// A shape that repeats horizontally and scrolls at [factor] of the
/// background offset.
class _Layer {
  _Layer(this.path, this.period, this.factor);

  final Path path;
  final double period;
  final double factor;

  void draw(Canvas canvas, double offset, double screenWidth, Paint paint) {
    var x = -((offset * factor) % period);
    if (x > 0) x -= period;
    while (x < screenWidth) {
      canvas.save();
      canvas.translate(x, 0);
      canvas.drawPath(path, paint);
      canvas.restore();
      x += period;
    }
  }
}
