import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';

/// Sky, sun, clouds, mountains and a city skyline above the horizon.
///
/// Performance: every layer is drawn ONCE into an image when the screen
/// size changes. Each frame only draws those images (a handful of cheap
/// textured rectangles), sliding them sideways at different speeds on
/// curves for parallax.
class Background extends Component with HasGameReference<RacingGame> {
  Background() : super(priority: 0);

  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.low;

  _Layer? _sky;
  _Layer? _clouds;
  _Layer? _mountains;
  _Layer? _hills;
  _Layer? _city;

  double _cloudDrift = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _disposeLayers();
    if (size.x <= 0 || size.y <= 0) return;
    _buildLayers(size.x, size.y, game.view.horizonY);
  }

  @override
  void onRemove() {
    _disposeLayers();
    super.onRemove();
  }

  @override
  void update(double dt) {
    _cloudDrift += dt * 60; // clouds slowly drift even on straights
  }

  @override
  void render(Canvas canvas) {
    final w = game.view.width;
    final offset = game.skyOffset * w;
    _sky?.draw(canvas, 0, w, _imagePaint);
    _clouds?.draw(canvas, offset + _cloudDrift, w, _imagePaint);
    _mountains?.draw(canvas, offset, w, _imagePaint);
    _hills?.draw(canvas, offset, w, _imagePaint);
    _city?.draw(canvas, offset, w, _imagePaint);
  }

  void _disposeLayers() {
    for (final layer in [_sky, _clouds, _mountains, _hills, _city]) {
      layer?.image.dispose();
    }
    _sky = _clouds = _mountains = _hills = _city = null;
  }

  // ---------------------------------------------------------------------------
  // Baking the layers into images
  // ---------------------------------------------------------------------------

  void _buildLayers(double w, double h, double horizon) {
    final ratio = min(2.0, game.pixelRatio);
    final period = w * 1.6;
    final random = Random(42);

    // Sky + sun (does not scroll). A margin hides edges during screen shake.
    const margin = 40.0;
    _sky = _Layer.bake(
      left: -margin,
      top: -margin,
      width: w + margin * 2,
      height: horizon + margin + 2,
      ratio: ratio,
      factor: 0,
      repeat: false,
      draw: (canvas) => _drawSky(canvas, w, h, horizon, margin),
    );

    _clouds = _Layer.bake(
      top: 0,
      width: period,
      height: horizon * 0.85,
      ratio: ratio,
      factor: 0.03,
      draw: (canvas) => _drawClouds(canvas, random, period, horizon, h),
    );

    final mountainTop = horizon - h * 0.16;
    _mountains = _Layer.bake(
      top: mountainTop,
      width: period,
      height: horizon + 2 - mountainTop,
      ratio: ratio,
      factor: 0.06,
      draw: (canvas) {
        canvas.translate(0, -mountainTop);
        final paint = Paint()
          ..shader = Gradient.linear(
            Offset(0, horizon - h * 0.16),
            Offset(0, horizon),
            const [Color(0xFF7B7FB5), Color(0xFFB7A6C9)],
          );
        final ridge = _ridge(random, period, horizon, h * 0.15, h * 0.05, 7);
        canvas.drawPath(ridge.$1, paint);
        canvas.drawPath(ridge.$2, Paint()..color = const Color(0xFFE6E1F0));
      },
    );

    final hillTop = horizon - h * 0.085;
    _hills = _Layer.bake(
      top: hillTop,
      width: period,
      height: horizon + 2 - hillTop,
      ratio: ratio,
      factor: 0.13,
      draw: (canvas) {
        canvas.translate(0, -hillTop);
        final paint = Paint()
          ..shader = Gradient.linear(
            Offset(0, horizon - h * 0.08),
            Offset(0, horizon),
            const [Color(0xFF4F6A8F), Color(0xFF8E97B3)],
          );
        canvas.drawPath(
            _ridge(random, period, horizon, h * 0.075, h * 0.03, 11).$1, paint);
      },
    );

    final cityTop = horizon - h * 0.14;
    _city = _Layer.bake(
      top: cityTop,
      width: period,
      height: horizon + 2 - cityTop,
      ratio: ratio,
      factor: 0.24,
      draw: (canvas) {
        canvas.translate(0, -cityTop);
        _drawCity(canvas, random, period, horizon, w, h);
      },
    );
  }

  void _drawSky(Canvas canvas, double w, double h, double horizon,
      double margin) {
    canvas.translate(margin, margin);
    canvas.drawRect(
      Rect.fromLTRB(-margin, -margin, w + margin, horizon + 2),
      Paint()
        ..shader = Gradient.linear(
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
        ),
    );

    // Sun with a soft glow (free here: it's baked into the image once).
    final sunRadius = h * 0.045;
    final sun = Offset(w * 0.68, horizon - h * 0.085);
    canvas.drawCircle(
      sun,
      sunRadius * 4,
      Paint()
        ..shader = Gradient.radial(
          sun,
          sunRadius * 4,
          const [Color(0x88FFE0B2), Color(0x33FFAB91), Color(0x00FFAB91)],
          const [0.0, 0.4, 1.0],
        ),
    );
    canvas.drawCircle(
      sun,
      sunRadius,
      Paint()
        ..shader = Gradient.linear(
          sun.translate(0, -sunRadius),
          sun.translate(0, sunRadius),
          const [Color(0xFFFFF3C4), Color(0xFFFF9E6B)],
        ),
    );
  }

  /// A few soft clouds built from overlapping ovals, with darker undersides.
  void _drawClouds(Canvas canvas, Random random, double period,
      double horizon, double h) {
    final clouds = Path();
    final shades = Path();
    for (var i = 0; i < 5; i++) {
      final cx = period * (i + 0.2 + random.nextDouble() * 0.6) / 5;
      final cy = horizon * (0.18 + random.nextDouble() * 0.5);
      final size = h * (0.025 + random.nextDouble() * 0.02);
      for (var j = 0; j < 4; j++) {
        final ox = (j - 1.5) * size * 1.1;
        final oy = j.isEven ? 0.0 : -size * 0.35;
        clouds.addOval(Rect.fromCenter(
            center: Offset(cx + ox, cy + oy),
            width: size * 2.2,
            height: size * 1.3));
        shades.addOval(Rect.fromCenter(
            center: Offset(cx + ox + size * 0.1, cy + oy + size * 0.22),
            width: size * 2.2,
            height: size * 1.3));
      }
    }
    canvas.drawPath(shades, Paint()..color = const Color(0x66B79AC4));
    canvas.drawPath(
      clouds,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, horizon * 0.1),
          Offset(0, horizon * 0.75),
          const [Color(0xCCF4EEFF), Color(0xB3FFD9C7)],
        ),
    );
  }

  /// A mountain ridge made of a few sine waves, plus its snow caps.
  /// Repeats seamlessly every [period] pixels.
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
      final n = (v + 1) / 2;
      heights.add(minHeight + (maxHeight - minHeight) * n * n);
    }

    final ridge = Path()..moveTo(0, horizon + 2);
    for (var i = 0; i <= steps; i++) {
      ridge.lineTo(period * i / steps, horizon - heights[i]);
    }
    ridge
      ..lineTo(period, horizon + 2)
      ..close();

    final snowLine = minHeight + (maxHeight - minHeight) * 0.72;
    final snow = Path();
    for (var i = 0; i < steps; i++) {
      final h1 = heights[i];
      final h2 = heights[i + 1];
      if (h1 > snowLine && h2 > snowLine) {
        final x1 = period * i / steps;
        final x2 = period * (i + 1) / steps;
        snow
          ..moveTo(x1, horizon - h1)
          ..lineTo(x2, horizon - h2)
          ..lineTo(x2, horizon - h2 + (h2 - snowLine) * 0.5)
          ..lineTo(x1, horizon - h1 + (h1 - snowLine) * 0.5)
          ..close();
      }
    }
    return (ridge, snow);
  }

  /// City buildings with lit windows and red beacons on the tallest towers.
  void _drawCity(Canvas canvas, Random random, double period, double horizon,
      double w, double h) {
    final buildings = Path();
    final windows = Path();
    final beacons = Path();

    final cityStart = period * 0.15;
    final cityEnd = period * 0.65;
    var x = cityStart;
    while (x < cityEnd) {
      final bw = w * (0.025 + random.nextDouble() * 0.04);
      final centre =
          1 - ((x - cityStart) / (cityEnd - cityStart) - 0.5).abs() * 2;
      final bh = h * (0.02 + random.nextDouble() * 0.05 + centre * 0.05);
      final rect = Rect.fromLTRB(x, horizon - bh, x + bw, horizon + 2);
      buildings.addRect(rect);

      final win = max(1.2, w * 0.004);
      for (var wy = rect.top + win * 2;
          wy < horizon - win * 2;
          wy += win * 2.4) {
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

    canvas.drawPath(
      buildings,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, horizon - h * 0.1),
          Offset(0, horizon),
          const [Color(0xFF2A3157), Color(0xFF4A4F78)],
        ),
    );
    canvas.drawPath(windows, Paint()..color = const Color(0xCCFFD180));
    canvas.drawPath(beacons, Paint()..color = const Color(0xFFFF5252));
  }
}

/// One background layer baked into an image. Repeating layers tile
/// horizontally every [width] pixels and scroll at [factor] of the offset.
class _Layer {
  _Layer._(this.image, this.left, this.top, this.width, this.height,
      this.factor, this.repeat)
      : _src = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());

  factory _Layer.bake({
    double left = 0,
    required double top,
    required double width,
    required double height,
    required double ratio,
    required double factor,
    bool repeat = true,
    required void Function(Canvas canvas) draw,
  }) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio);
    draw(canvas);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      max(1, (width * ratio).ceil()),
      max(1, (height * ratio).ceil()),
    );
    picture.dispose();
    return _Layer._(image, left, top, width, height, factor, repeat);
  }

  final Image image;
  final double left;
  final double top;
  final double width;
  final double height;
  final double factor;
  final bool repeat;
  final Rect _src;

  void draw(Canvas canvas, double offset, double screenWidth, Paint paint) {
    if (!repeat) {
      canvas.drawImageRect(
          image, _src, Rect.fromLTWH(left, top, width, height), paint);
      return;
    }
    // Start one tile to the left so screen shake never shows a gap.
    var x = -((offset * factor) % width) - width;
    while (x < screenWidth + 40) {
      if (x + width > -40) {
        canvas.drawImageRect(
            image, _src, Rect.fromLTWH(x, top, width, height), paint);
      }
      x += width;
    }
  }
}
