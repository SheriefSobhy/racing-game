import 'dart:math';
import 'dart:ui';

/// Draws a car seen from behind and a little above.
///
/// The car is drawn in "unit" coordinates: 1.0 wide, centred on x = 0,
/// with the ground at y = 0 and the roof at about y = -0.72. Scale the
/// canvas by the car's width in pixels before calling [paintCar].
///
/// Gradients are created once per body colour and cached, so drawing
/// many cars every frame stays cheap.
class CarPainter {
  CarPainter._();

  static final Map<Color, _BodyPaints> _cache = {};

  static final Paint _shadow = Paint()
    ..shader = Gradient.radial(
      Offset.zero,
      0.62,
      const [Color(0x88000000), Color(0x55000000), Color(0x00000000)],
      const [0.0, 0.6, 1.0],
    );

  static final Paint _tire = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -0.22),
      const Offset(0, 0),
      const [Color(0xFF3A3A3A), Color(0xFF0E0E0E)],
    );

  static final Paint _sideShade = Paint()
    ..shader = Gradient.linear(
      const Offset(-0.5, 0),
      const Offset(0.5, 0),
      const [
        Color(0x66000000),
        Color(0x00000000),
        Color(0x00000000),
        Color(0x77000000),
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

  static final Paint _glassShine = Paint()..color = const Color(0x30FFFFFF);
  static final Paint _bodyLine = Paint()..color = const Color(0x40000000);
  static final Paint _highlight = Paint()..color = const Color(0x55FFFFFF);

  static final Paint _tailGlow = Paint()..color = const Color(0x44FF1744);
  static final Paint _tailLight = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -0.38),
      const Offset(0, -0.30),
      const [Color(0xFFFF6E6E), Color(0xFFC62828)],
    );
  static final Paint _tailCore = Paint()..color = const Color(0xFFFFCDD2);

  static final Paint _bumper = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -0.17),
      const Offset(0, -0.08),
      const [Color(0xFF455A64), Color(0xFF1C262B)],
    );
  static final Paint _plate = Paint()..color = const Color(0xFFF2F2F2);
  static final Paint _plateText = Paint()..color = const Color(0xFF37474F);

  static final Paint _spoiler = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -0.53),
      const Offset(0, -0.48),
      const [Color(0xFF424242), Color(0xFF121212)],
    );
  static final Paint _exhaust = Paint()..color = const Color(0xFF9E9E9E);
  static final Paint _exhaustHole = Paint()..color = const Color(0xFF1A1A1A);
  static final Paint _flameOuter = Paint()..color = const Color(0xCCFF9100);
  static final Paint _flameInner = Paint()..color = const Color(0xEEB3E5FC);

  static _BodyPaints _paintsFor(Color body) =>
      _cache.putIfAbsent(body, () => _BodyPaints(body));

  /// [lean] is -1..1: how far left/right of the screen centre the car is.
  /// It shifts the roof sideways a little to fake 3D perspective.
  /// [boost] 0..1 shows exhaust flames (player only).
  static void paintCar(
    Canvas canvas, {
    required Color body,
    double lean = 0,
    bool isPlayer = false,
    double boost = 0,
    double time = 0,
  }) {
    final paints = _paintsFor(body);
    final l = lean.clamp(-1.0, 1.0) * 0.07;

    // Soft shadow on the road.
    canvas.save();
    canvas.scale(1, 0.16);
    canvas.drawCircle(const Offset(0, -0.05), 0.62, _shadow);
    canvas.restore();

    // Tyres.
    for (final x in const [-0.47, 0.31]) {
      canvas.drawRRect(
        RRect.fromLTRBR(x, -0.23, x + 0.16, 0.0, const Radius.circular(0.04)),
        _tire,
      );
    }

    // Exhaust flames behind the car (drawn under the bumper).
    if (isPlayer && boost > 0) {
      final flicker = 0.75 + 0.25 * sin(time * 60);
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

    // Main body with vertical shading and darker sides.
    final bodyRect =
        RRect.fromLTRBR(-0.5, -0.46, 0.5, -0.09, const Radius.circular(0.08));
    canvas.drawRRect(bodyRect, paints.body);
    canvas.drawRRect(bodyRect, _sideShade);

    // Cabin (sloping sides) and roof, shifted by the lean.
    final cabin = Path()
      ..moveTo(-0.43, -0.44)
      ..lineTo(-0.32 + l, -0.67)
      ..quadraticBezierTo(-0.31 + l, -0.71, -0.26 + l, -0.71)
      ..lineTo(0.26 + l, -0.71)
      ..quadraticBezierTo(0.31 + l, -0.71, 0.32 + l, -0.67)
      ..lineTo(0.43, -0.44)
      ..close();
    canvas.drawPath(cabin, paints.cabin);

    final window = Path()
      ..moveTo(-0.37, -0.465)
      ..lineTo(-0.28 + l, -0.655)
      ..lineTo(0.28 + l, -0.655)
      ..lineTo(0.37, -0.465)
      ..close();
    canvas.drawPath(window, _glass);
    // Diagonal reflection on the rear window.
    final shine = Path()
      ..moveTo(-0.18 + l, -0.655)
      ..lineTo(-0.06 + l, -0.655)
      ..lineTo(-0.2, -0.465)
      ..lineTo(-0.32, -0.465)
      ..close();
    canvas.drawPath(shine, _glassShine);

    canvas.drawRRect(
      RRect.fromLTRBR(-0.27 + l, -0.735, 0.27 + l, -0.685,
          const Radius.circular(0.025)),
      paints.roof,
    );

    // Shine along the top of the trunk and the trunk lid line.
    canvas.drawRect(const Rect.fromLTRB(-0.44, -0.455, 0.44, -0.44), _highlight);
    canvas.drawRect(const Rect.fromLTRB(-0.4, -0.405, 0.4, -0.395), _bodyLine);

    // Tail lights with glow.
    for (final x in const [-0.48, 0.25]) {
      canvas.drawRRect(
        RRect.fromLTRBR(x - 0.03, -0.41, x + 0.26, -0.27,
            const Radius.circular(0.05)),
        _tailGlow,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(x, -0.385, x + 0.23, -0.3, const Radius.circular(0.03)),
        _tailLight,
      );
      canvas.drawRect(
          Rect.fromLTRB(x + 0.03, -0.37, x + 0.2, -0.355), _tailCore);
    }

    // Licence plate and bumper.
    canvas.drawRRect(
      RRect.fromLTRBR(-0.12, -0.28, 0.12, -0.19, const Radius.circular(0.015)),
      _plate,
    );
    canvas.drawRect(const Rect.fromLTRB(-0.08, -0.245, 0.08, -0.225), _plateText);
    canvas.drawRRect(
      RRect.fromLTRBR(-0.49, -0.17, 0.49, -0.085, const Radius.circular(0.04)),
      _bumper,
    );

    if (isPlayer) {
      // Rear spoiler on struts.
      canvas.drawRect(const Rect.fromLTRB(-0.3, -0.5, -0.26, -0.45), _spoiler);
      canvas.drawRect(const Rect.fromLTRB(0.26, -0.5, 0.3, -0.45), _spoiler);
      canvas.drawRRect(
        RRect.fromLTRBR(-0.47, -0.54, 0.47, -0.49, const Radius.circular(0.02)),
        _spoiler,
      );
      // Twin exhaust pipes.
      for (final x in const [-0.2, 0.2]) {
        canvas.drawCircle(Offset(x, -0.1), 0.035, _exhaust);
        canvas.drawCircle(Offset(x, -0.1), 0.022, _exhaustHole);
      }
    }
  }
}

/// Gradients that depend on the body colour.
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
        roof = Paint()..color = _shade(c, 0.4);

  final Paint body;
  final Paint cabin;
  final Paint roof;

  /// Positive amount = lighter, negative = darker.
  static Color _shade(Color c, double amount) => amount >= 0
      ? Color.lerp(c, const Color(0xFFFFFFFF), amount)!
      : Color.lerp(c, const Color(0xFF000000), -amount)!;
}
