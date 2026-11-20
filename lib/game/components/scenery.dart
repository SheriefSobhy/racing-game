import 'dart:ui';

import '../perspective.dart';
import '../world_object.dart';

enum SceneryType { pine, roundTree, bush, lamp, billboard, chevron }

/// A roadside decoration. Everything is drawn in world units
/// (ground at y = 0, up is negative) and scaled by distance.
///
/// Performance: shapes and paints are created once. Far-away items are
/// drawn as a single simple shape; shadows and small details only appear
/// up close.
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

  /// Below this height (pixels) items are skipped entirely.
  static const double _minPixels = 3;

  /// Below this height (pixels) items are drawn as one simple shape.
  static const double _simplePixels = 28;

  @override
  void paint(Canvas canvas, ScreenPoint point, Perspective view) {
    final pixelHeight = _height * point.scale;
    if (pixelHeight < _minPixels) return;
    final simple = pixelHeight < _simplePixels;

    canvas.save();
    canvas.translate(point.x, point.y);
    canvas.scale(point.scale);
    switch (type) {
      case SceneryType.pine:
        if (!simple) {
          canvas.drawOval(_pineShadow, _shadow);
          canvas.drawRect(_pineTrunk, _trunk);
        }
        canvas.drawPath(_pineShape, simple ? _pineFlat : _pinePaint);
      case SceneryType.roundTree:
        if (!simple) {
          canvas.drawOval(_roundShadow, _shadow);
          canvas.drawRect(_roundTrunk, _trunk);
        }
        canvas.drawPath(_roundShape, simple ? _roundFlat : _roundPaint);
      case SceneryType.bush:
        canvas.drawPath(_bushShape, _bushPaint);
      case SceneryType.lamp:
        canvas.scale(facing, 1);
        canvas.drawRect(_lampPole, simple ? _metalFlat : _metal);
        canvas.drawRect(_lampArm, simple ? _metalFlat : _metal);
        if (!simple) {
          canvas.drawRect(_lampBase, _darkMetal);
          canvas.drawRRect(_lampHead, _darkMetal);
          canvas.drawOval(_lampBulb, _lampLight);
        }
      case SceneryType.billboard:
        final board = _billboardPaints[variant % _billboardPaints.length];
        if (simple) {
          canvas.drawRect(_billboardPanel, board);
        } else {
          _paintBillboard(canvas, board);
        }
      case SceneryType.chevron:
        canvas.scale(facing, 1);
        if (simple) {
          canvas.drawRect(_chevronPanel, _yellow);
        } else {
          canvas.drawRect(_chevronPost, _metal);
          canvas.drawRRect(_chevronBorder, _black);
          canvas.drawRect(_chevronPanel, _yellow);
          canvas.drawPath(_chevronArrow, _black);
        }
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

  void _paintBillboard(Canvas canvas, Paint board) {
    canvas.drawRect(const Rect.fromLTRB(-420, -900, -360, 0), _metal);
    canvas.drawRect(const Rect.fromLTRB(360, -900, 420, 0), _metal);
    canvas.drawRRect(_billboardFrame, _darkMetal);
    canvas.drawRect(_billboardPanel, board);
    canvas.drawCircle(const Offset(-380, -1190), 150, _white);
    canvas.drawCircle(const Offset(-380, -1190), 90, _yellow);
    canvas.drawRRect(_billboardText1, _white);
    canvas.drawRRect(_billboardText2, _whiteSoft);
  }

  // ---------------------------------------------------------------------------
  // Shared paints and shapes (built once).
  // ---------------------------------------------------------------------------

  static final Paint _shadow = Paint()..color = const Color(0x33000000);
  static final Paint _trunk = Paint()..color = const Color(0xFF6D4C41);

  static final Rect _pineShadow =
      Rect.fromCenter(center: Offset.zero, width: 900, height: 160);
  static const Rect _pineTrunk = Rect.fromLTRB(-55, -320, 55, 0);
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
  static final Paint _pineFlat = Paint()..color = const Color(0xFF3E7D45);

  static final Rect _roundShadow =
      Rect.fromCenter(center: Offset.zero, width: 1000, height: 170);
  static const Rect _roundTrunk = Rect.fromLTRB(-60, -560, 60, 0);
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
  static final Paint _roundFlat = Paint()..color = const Color(0xFF4C8F45);

  static final Path _bushShape = Path()
    ..addOval(Rect.fromCenter(
        center: const Offset(-160, -140), width: 380, height: 280))
    ..addOval(Rect.fromCenter(
        center: const Offset(150, -150), width: 400, height: 300))
    ..addOval(
        Rect.fromCenter(center: const Offset(0, -220), width: 380, height: 300));
  static final Paint _bushPaint = Paint()..color = const Color(0xFF558B2F);

  static final Paint _metal = Paint()
    ..shader = Gradient.linear(
      const Offset(-25, 0),
      const Offset(25, 0),
      const [Color(0xFFCFD8DC), Color(0xFF78909C), Color(0xFF455A64)],
      const [0.0, 0.4, 1.0],
    );
  static final Paint _metalFlat = Paint()..color = const Color(0xFF8A9AA3);
  static final Paint _darkMetal = Paint()..color = const Color(0xFF37474F);
  static final Paint _lampLight = Paint()..color = const Color(0xFFFFF8E1);
  static const Rect _lampBase = Rect.fromLTRB(-55, -130, 55, 0);
  static const Rect _lampPole = Rect.fromLTRB(-22, -1720, 22, 0);
  static const Rect _lampArm = Rect.fromLTRB(0, -1720, 460, -1690);
  static final RRect _lampHead =
      RRect.fromLTRBR(340, -1740, 540, -1670, const Radius.circular(30));
  static const Rect _lampBulb = Rect.fromLTRB(360, -1685, 520, -1650);

  static final List<Paint> _billboardPaints = [
    for (final c in const [
      Color(0xFFF4511E),
      Color(0xFF039BE5),
      Color(0xFF8E24AA),
      Color(0xFF43A047),
    ])
      Paint()..color = c,
  ];
  static final RRect _billboardFrame =
      RRect.fromLTRBR(-640, -1540, 640, -830, const Radius.circular(30));
  static const Rect _billboardPanel = Rect.fromLTRB(-600, -1500, 600, -870);
  static final RRect _billboardText1 =
      RRect.fromLTRBR(-170, -1330, 500, -1240, const Radius.circular(40));
  static final RRect _billboardText2 =
      RRect.fromLTRBR(-170, -1180, 380, -1110, const Radius.circular(35));
  static final Paint _white = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _whiteSoft = Paint()..color = const Color(0xFFE0E0E0);
  static final Paint _yellow = Paint()..color = const Color(0xFFFFD600);
  static final Paint _black = Paint()..color = const Color(0xFF212121);

  static const Rect _chevronPost = Rect.fromLTRB(-20, -440, 20, 0);
  static final RRect _chevronBorder =
      RRect.fromLTRBR(-210, -810, 210, -410, const Radius.circular(20));
  static const Rect _chevronPanel = Rect.fromLTRB(-180, -780, 180, -440);
  static final Path _chevronArrow = Path()
    ..moveTo(-110, -760)
    ..lineTo(-10, -760)
    ..lineTo(120, -610)
    ..lineTo(-10, -460)
    ..lineTo(-110, -460)
    ..lineTo(20, -610)
    ..close();
}
