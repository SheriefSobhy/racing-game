import 'dart:math';
import 'dart:ui';

/// Draws a car seen from behind and a little above.
///
/// The car is drawn in "unit" coordinates: 1.0 wide, centred on x = 0,
/// with the ground at y = 0 and the roof at about y = -0.72. Scale the
/// canvas by the car's width in pixels before calling [paintCar].
///
/// Performance: every Path, Paint and gradient is created once and reused.
/// The perspective "lean" is done with a canvas skew instead of building
/// new shapes, and far-away cars use a much simpler drawing.
class CarPainter {
  CarPainter._();

  /// Cars narrower than this (in pixels) use the simple drawing.
  static const double detailWidth = 30;

  static final Map<Color, _BodyPaints> _cache = {};

  static final Paint _shadow = Paint()..color = const Color(0x4D000000);
  static final Paint _tire = Paint()..color = const Color(0xFF161616);
  static final Paint _sideShade = Paint()
    ..shader = Gradient.linear(
      const Offset(-0.5, 0),
      const Offset(0.5, 0),
      const [
        Color(0x55000000),
        Color(0x00000000),
        Color(0x00000000),
        Color(0x66000000),
      ],
      const [0.0, 0.2, 0.75, 1.0],
    );
  static final Paint _glass = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -0.66),
      const Offset(0, -0.46),
      const [Color(0xFFA9D2F0), Color(0xFF4A6B8C), Color(0xFF16202C)],
      const [0.0, 0.35, 1.0],
    );
  static final Paint _glassShine = Paint()..color = const Color(0xFF5E7E9C);
  static final Paint _bodyLine = Paint()..color = const Color(0x40000000);
  static final Paint _tailLight = Paint()..color = const Color(0xFFE53935);
  static final Paint _tailCore = Paint()..color = const Color(0xFFFF8A80);
  static final Paint _bumper = Paint()..color = const Color(0xFF263238);
  static final Paint _plate = Paint()..color = const Color(0xFFF2F2F2);
  static final Paint _plateText = Paint()..color = const Color(0xFF37474F);
  static final Paint _spoiler = Paint()..color = const Color(0xFF1E1E1E);
  static final Paint _exhaust = Paint()..color = const Color(0xFF9E9E9E);
  static final Paint _exhaustHole = Paint()..color = const Color(0xFF1A1A1A);
  static final Paint _flameOuter = Paint()..color = const Color(0xFFFF9100);
  static final Paint _flameInner = Paint()..color = const Color(0xFFE1F5FE);

  // Shapes in unit coordinates (built once).
  static final RRect _bodyRect =
      RRect.fromLTRBR(-0.5, -0.46, 0.5, -0.09, const Radius.circular(0.08));
  static final Path _cabin = Path()
    ..moveTo(-0.43, -0.44)
    ..lineTo(-0.32, -0.67)
    ..quadraticBezierTo(-0.31, -0.71, -0.26, -0.71)
    ..lineTo(0.26, -0.71)
    ..quadraticBezierTo(0.31, -0.71, 0.32, -0.67)
    ..lineTo(0.43, -0.44)
    ..close();
  static final Path _window = Path()
    ..moveTo(-0.37, -0.465)
    ..lineTo(-0.28, -0.655)
    ..lineTo(0.28, -0.655)
    ..lineTo(0.37, -0.465)
    ..close();
  static final Path _shine = Path()
    ..moveTo(-0.18, -0.655)
    ..lineTo(-0.06, -0.655)
    ..lineTo(-0.2, -0.465)
    ..lineTo(-0.32, -0.465)
    ..close();
  static final RRect _roof =
      RRect.fromLTRBR(-0.27, -0.735, 0.27, -0.685, const Radius.circular(0.025));
  static final Rect _shadowRect =
      Rect.fromCenter(center: const Offset(0, -0.01), width: 1.16, height: 0.13);
  static final RRect _tireLeft =
      RRect.fromLTRBR(-0.47, -0.23, -0.31, 0.0, const Radius.circular(0.04));
  static final RRect _tireRight =
      RRect.fromLTRBR(0.31, -0.23, 0.47, 0.0, const Radius.circular(0.04));
  static final RRect _tailLeft =
      RRect.fromLTRBR(-0.48, -0.385, -0.25, -0.3, const Radius.circular(0.03));
  static final RRect _tailRight =
      RRect.fromLTRBR(0.25, -0.385, 0.48, -0.3, const Radius.circular(0.03));
  static final RRect _plateRect =
      RRect.fromLTRBR(-0.12, -0.28, 0.12, -0.19, const Radius.circular(0.015));
  static final RRect _bumperRect =
      RRect.fromLTRBR(-0.49, -0.17, 0.49, -0.085, const Radius.circular(0.04));
  static final RRect _spoilerRect =
      RRect.fromLTRBR(-0.47, -0.54, 0.47, -0.49, const Radius.circular(0.02));

  static _BodyPaints _paintsFor(Color body) =>
      _cache.putIfAbsent(body, () => _BodyPaints(body));

  /// [pixelWidth] is the car's width on screen (for level of detail).
  /// [lean] is -1..1: how far left/right of the screen centre the car is;
  /// it shifts the roof sideways a little to fake perspective.
  /// [boost] 0..1 shows exhaust flames (player only).
  static void paintCar(
    Canvas canvas, {
    required Color body,
    required double pixelWidth,
    double lean = 0,
    bool isPlayer = false,
    double boost = 0,
    double time = 0,
  }) {
    final paints = _paintsFor(body);

    if (pixelWidth < detailWidth) {
      // Far away: just the main shapes.
      canvas.drawRRect(_bodyRect, paints.body);
      canvas.drawPath(_cabin, paints.cabin);
      canvas.drawRRect(_tailLeft, _tailLight);
      canvas.drawRRect(_tailRight, _tailLight);
      return;
    }

    canvas.drawOval(_shadowRect, _shadow);
    canvas.drawRRect(_tireLeft, _tire);
    canvas.drawRRect(_tireRight, _tire);

    if (isPlayer && boost > 0) {
      final flicker = 0.8 + 0.2 * sin(time * 40);
      for (final x in const [-0.2, 0.2]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, -0.07 + 0.03 * boost * flicker),
            width: 0.09 * boost,
            height: 0.12 * boost * flicker,
          ),
          _flameOuter,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, -0.085),
            width: 0.045 * boost,
            height: 0.06 * boost * flicker,
          ),
          _flameInner,
        );
      }
    }

    canvas.drawRRect(_bodyRect, paints.body);
    canvas.drawRRect(_bodyRect, _sideShade);

    // Cabin, window and roof, skewed sideways around the cabin's base.
    final l = lean.clamp(-1.0, 1.0) * 0.07;
    canvas.save();
    canvas.translate(0, -0.44);
    canvas.skew(-l / 0.27, 0);
    canvas.translate(0, 0.44);
    canvas.drawPath(_cabin, paints.cabin);
    canvas.drawPath(_window, _glass);
    canvas.drawPath(_shine, _glassShine);
    canvas.drawRRect(_roof, paints.roof);
    canvas.restore();

    canvas.drawRect(const Rect.fromLTRB(-0.44, -0.455, 0.44, -0.44),
        paints.highlight);
    canvas.drawRect(
        const Rect.fromLTRB(-0.4, -0.405, 0.4, -0.395), _bodyLine);

    canvas.drawRRect(_tailLeft, _tailLight);
    canvas.drawRRect(_tailRight, _tailLight);
    canvas.drawRect(const Rect.fromLTRB(-0.45, -0.37, -0.28, -0.355), _tailCore);
    canvas.drawRect(const Rect.fromLTRB(0.28, -0.37, 0.45, -0.355), _tailCore);

    canvas.drawRRect(_plateRect, _plate);
    canvas.drawRect(
        const Rect.fromLTRB(-0.08, -0.245, 0.08, -0.225), _plateText);
    canvas.drawRRect(_bumperRect, _bumper);

    if (isPlayer) {
      canvas.drawRect(const Rect.fromLTRB(-0.3, -0.5, -0.26, -0.45), _spoiler);
      canvas.drawRect(const Rect.fromLTRB(0.26, -0.5, 0.3, -0.45), _spoiler);
      canvas.drawRRect(_spoilerRect, _spoiler);
      for (final x in const [-0.2, 0.2]) {
        canvas.drawCircle(Offset(x, -0.1), 0.035, _exhaust);
        canvas.drawCircle(Offset(x, -0.1), 0.022, _exhaustHole);
      }
    }
  }
}

/// Paints that depend on the body colour (cached per colour).
class _BodyPaints {
  _BodyPaints(Color c)
      : body = Paint()
          ..shader = Gradient.linear(
            const Offset(0, -0.46),
            const Offset(0, -0.09),
            [_shade(c, 0.35), c, _shade(c, -0.45)],
            const [0.0, 0.35, 1.0],
          ),
        cabin = Paint()
          ..shader = Gradient.linear(
            const Offset(0, -0.71),
            const Offset(0, -0.44),
            [_shade(c, 0.1), _shade(c, -0.3)],
          ),
        roof = Paint()..color = _shade(c, 0.4),
        highlight = Paint()..color = _shade(c, 0.55);

  final Paint body;
  final Paint cabin;
  final Paint roof;
  final Paint highlight;

  /// Positive amount = lighter, negative = darker.
  static Color _shade(Color c, double amount) => amount >= 0
      ? Color.lerp(c, const Color(0xFFFFFFFF), amount)!
      : Color.lerp(c, const Color(0xFF000000), -amount)!;
}
