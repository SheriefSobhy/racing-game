import 'dart:ui';

import '../perspective.dart';
import '../world_object.dart';

enum SceneryType { pine, roundTree, bush, lamp, billboard, chevron }

/// A roadside decoration. Everything is drawn in world units
/// (ground at y = 0, up is negative) and scaled by distance.
class SceneryItem extends WorldObject {
  SceneryItem({
    required this.type,
    required super.x,
    required super.z,
    this.facing = 1,
    this.variant = 0,
  });

  final SceneryType type;

  /// 1 or -1: which way lamps/chevrons point (towards the road / the curve).
  final double facing;

  /// Picks a colour scheme (billboards).
  final int variant;

  /// Whether the item being drawn is close enough for small details.
  static bool _detail = true;

  @override
  void paint(Canvas canvas, ScreenPoint point, Perspective view) {
    // Skip things that would be smaller than a few pixels.
    final pixelHeight = _height * point.scale;
    if (pixelHeight < 3) return;
    // Far away, skip small details (shadows, trunks) to save draw calls.
    _detail = pixelHeight > 36;

    canvas.save();
    canvas.translate(point.x, point.y);
    canvas.scale(point.scale);
    switch (type) {
      case SceneryType.pine:
        _paintPine(canvas);
      case SceneryType.roundTree:
        _paintRoundTree(canvas);
      case SceneryType.bush:
        _paintBush(canvas);
      case SceneryType.lamp:
        canvas.scale(facing, 1);
        _paintLamp(canvas);
      case SceneryType.billboard:
        _paintBillboard(canvas);
      case SceneryType.chevron:
        canvas.scale(facing, 1);
        _paintChevron(canvas);
    }
    canvas.restore();
  }

  double get _height => switch (type) {
        SceneryType.pine => 1500,
        SceneryType.roundTree => 1350,
        SceneryType.bush => 350,
        SceneryType.lamp => 1750,
        SceneryType.billboard => 1550,
        SceneryType.chevron => 800,
      };

  // ---------------------------------------------------------------------------
  // Shared paints and shapes (built once).
  // ---------------------------------------------------------------------------

  static final Paint _shadow = Paint()..color = const Color(0x40000000);
  static final Paint _trunk = Paint()
    ..shader = Gradient.linear(
      const Offset(-60, 0),
      const Offset(60, 0),
      const [Color(0xFF8D6E63), Color(0xFF4E342E)],
    );

  static final Path _pineShape = Path()
    ..moveTo(0, -1500)
    ..lineTo(330, -850)
    ..lineTo(200, -860)
    ..lineTo(430, -560)
    ..lineTo(260, -570)
    ..lineTo(520, -280)
    ..lineTo(-520, -280)
    ..lineTo(-260, -570)
    ..lineTo(-430, -560)
    ..lineTo(-200, -860)
    ..lineTo(-330, -850)
    ..close();
  static final Paint _pinePaint = Paint()
    ..shader = Gradient.linear(
      const Offset(-500, -1400),
      const Offset(500, -300),
      const [Color(0xFF66BB6A), Color(0xFF2E7D32), Color(0xFF103D14)],
      const [0.0, 0.45, 1.0],
    );

  static final Path _roundShape = Path()
    ..addOval(Rect.fromCircle(center: const Offset(0, -980), radius: 360))
    ..addOval(Rect.fromCircle(center: const Offset(-270, -760), radius: 300))
    ..addOval(Rect.fromCircle(center: const Offset(270, -770), radius: 300))
    ..addOval(Rect.fromCircle(center: const Offset(0, -640), radius: 330));
  static final Paint _roundPaint = Paint()
    ..shader = Gradient.radial(
      const Offset(-180, -1100),
      900,
      const [Color(0xFF9CCC65), Color(0xFF388E3C), Color(0xFF1B5E20)],
      const [0.0, 0.55, 1.0],
    );

  static final Path _bushShape = Path()
    ..addOval(Rect.fromCenter(
        center: const Offset(-160, -140), width: 380, height: 280))
    ..addOval(Rect.fromCenter(
        center: const Offset(150, -150), width: 400, height: 300))
    ..addOval(
        Rect.fromCenter(center: const Offset(0, -220), width: 380, height: 300));
  static final Paint _bushPaint = Paint()
    ..shader = Gradient.linear(
      const Offset(0, -370),
      const Offset(0, 0),
      const [Color(0xFF7CB342), Color(0xFF33691E)],
    );

  static final Paint _metal = Paint()
    ..shader = Gradient.linear(
      const Offset(-25, 0),
      const Offset(25, 0),
      const [Color(0xFFCFD8DC), Color(0xFF78909C), Color(0xFF455A64)],
      const [0.0, 0.4, 1.0],
    );
  static final Paint _darkMetal = Paint()..color = const Color(0xFF37474F);
  static final Paint _lampLight = Paint()..color = const Color(0xFFFFF8E1);
  static final Paint _lampGlow = Paint()
    ..shader = Gradient.radial(
      const Offset(440, -1640),
      260,
      const [Color(0x66FFF59D), Color(0x00FFF59D)],
    );

  static const _billboardColors = [
    [Color(0xFFFF7043), Color(0xFFD84315)],
    [Color(0xFF29B6F6), Color(0xFF0277BD)],
    [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
    [Color(0xFF66BB6A), Color(0xFF2E7D32)],
  ];
  static final List<Paint> _billboardPaints = [
    for (final c in _billboardColors)
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -1500),
          const Offset(0, -860),
          c,
        ),
  ];
  static final Paint _white = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _whiteSoft = Paint()..color = const Color(0xAAFFFFFF);
  static final Paint _yellow = Paint()..color = const Color(0xFFFFD600);
  static final Paint _black = Paint()..color = const Color(0xFF212121);

  static final Path _chevronArrow = Path()
    ..moveTo(-110, -760)
    ..lineTo(-10, -760)
    ..lineTo(120, -610)
    ..lineTo(-10, -460)
    ..lineTo(-110, -460)
    ..lineTo(20, -610)
    ..close();

  // ---------------------------------------------------------------------------

  void _paintPine(Canvas canvas) {
    if (_detail) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 900, height: 160),
          _shadow);
      canvas.drawRect(const Rect.fromLTRB(-55, -320, 55, 0), _trunk);
    }
    canvas.drawPath(_pineShape, _pinePaint);
  }

  void _paintRoundTree(Canvas canvas) {
    if (_detail) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 1000, height: 170),
          _shadow);
    }
    canvas.drawRect(const Rect.fromLTRB(-60, -560, 60, 0), _trunk);
    canvas.drawPath(_roundShape, _roundPaint);
  }

  void _paintBush(Canvas canvas) {
    if (_detail) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 820, height: 120),
          _shadow);
    }
    canvas.drawPath(_bushShape, _bushPaint);
  }

  void _paintLamp(Canvas canvas) {
    if (_detail) {
      canvas.drawRect(const Rect.fromLTRB(-55, -130, 55, 0), _darkMetal);
    }
    canvas.drawRect(const Rect.fromLTRB(-22, -1720, 22, 0), _metal);
    // Arm reaching over the road, lamp head and light.
    canvas.drawRect(const Rect.fromLTRB(0, -1720, 460, -1690), _metal);
    if (_detail) canvas.drawCircle(const Offset(440, -1640), 260, _lampGlow);
    canvas.drawRRect(
      RRect.fromLTRBR(340, -1740, 540, -1670, const Radius.circular(30)),
      _darkMetal,
    );
    canvas.drawOval(const Rect.fromLTRB(360, -1685, 520, -1650), _lampLight);
  }

  void _paintBillboard(Canvas canvas) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 1300, height: 140),
        _shadow);
    canvas.drawRect(const Rect.fromLTRB(-420, -900, -360, 0), _metal);
    canvas.drawRect(const Rect.fromLTRB(360, -900, 420, 0), _metal);
    canvas.drawRRect(
      RRect.fromLTRBR(-640, -1540, 640, -830, const Radius.circular(30)),
      _darkMetal,
    );
    canvas.drawRect(const Rect.fromLTRB(-600, -1500, 600, -870),
        _billboardPaints[variant % _billboardPaints.length]);
    // "Text" and a logo.
    canvas.drawCircle(const Offset(-380, -1190), 150, _white);
    canvas.drawCircle(const Offset(-380, -1190), 90, _yellow);
    canvas.drawRRect(
        RRect.fromLTRBR(-170, -1330, 500, -1240, const Radius.circular(40)),
        _white);
    canvas.drawRRect(
        RRect.fromLTRBR(-170, -1180, 380, -1110, const Radius.circular(35)),
        _whiteSoft);
    canvas.drawRRect(
        RRect.fromLTRBR(-170, -1060, 260, -1000, const Radius.circular(30)),
        _whiteSoft);
  }

  void _paintChevron(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTRB(-20, -440, 20, 0), _metal);
    canvas.drawRRect(
      RRect.fromLTRBR(-210, -810, 210, -410, const Radius.circular(20)),
      _black,
    );
    canvas.drawRect(const Rect.fromLTRB(-180, -780, 180, -440), _yellow);
    canvas.drawPath(_chevronArrow, _black);
  }
}
