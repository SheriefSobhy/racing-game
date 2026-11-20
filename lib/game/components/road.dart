import 'dart:ui';

import 'package:flame/components.dart';

import '../racing_game.dart';

/// Draws the grass, curbs, asphalt and moving lane markings.
class Road extends Component with HasGameReference<RacingGame> {
  static final _grass = Paint()..color = const Color(0xFF4CAF50);
  static final _grassDark = Paint()..color = const Color(0xFF43A047);
  static final _asphalt = Paint()..color = const Color(0xFF3B3F4A);
  static final _curbRed = Paint()..color = const Color(0xFFE53935);
  static final _curbWhite = Paint()..color = const Color(0xFFF5F5F5);
  static final _edgeLine = Paint()..color = const Color(0xFFFFD54F);
  static final _laneLine = Paint()..color = const Color(0xFFFFFFFF);

  /// How far the road has scrolled, in pixels.
  double _offset = 0;

  @override
  void update(double dt) {
    _offset += game.speed * dt;
    // Keep the number small; the pattern repeats every screen height anyway.
    if (_offset > game.size.y * 100) _offset -= game.size.y * 100;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final roadLeft = game.roadLeft;
    final roadRight = w - roadLeft;

    // Grass with moving stripes.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _grass);
    final band = h * 0.08;
    _drawRepeating(h, band * 2, (y) {
      canvas.drawRect(Rect.fromLTWH(0, y, roadLeft, band), _grassDark);
      canvas.drawRect(Rect.fromLTWH(roadRight, y, roadLeft, band), _grassDark);
    });

    // Asphalt.
    canvas.drawRect(Rect.fromLTRB(roadLeft, 0, roadRight, h), _asphalt);

    // Red / white curbs on both edges.
    final curbWidth = roadLeft * 0.3;
    final curbBlock = h * 0.035;
    canvas.drawRect(
        Rect.fromLTWH(roadLeft - curbWidth, 0, curbWidth, h), _curbWhite);
    canvas.drawRect(Rect.fromLTWH(roadRight, 0, curbWidth, h), _curbWhite);
    _drawRepeating(h, curbBlock * 2, (y) {
      canvas.drawRect(
          Rect.fromLTWH(roadLeft - curbWidth, y, curbWidth, curbBlock),
          _curbRed);
      canvas.drawRect(
          Rect.fromLTWH(roadRight, y, curbWidth, curbBlock), _curbRed);
    });

    // Solid yellow edge lines.
    final lineWidth = w * 0.012;
    final edgeInset = lineWidth * 1.5;
    canvas.drawRect(
        Rect.fromLTWH(roadLeft + edgeInset, 0, lineWidth, h), _edgeLine);
    canvas.drawRect(
        Rect.fromLTWH(roadRight - edgeInset - lineWidth, 0, lineWidth, h),
        _edgeLine);

    // Dashed white lane dividers.
    final dash = h * 0.06;
    for (var i = 1; i < RacingGame.laneCount; i++) {
      final x = roadLeft + game.laneWidth * i - lineWidth / 2;
      _drawRepeating(h, dash * 2, (y) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, lineWidth, dash),
            Radius.circular(lineWidth / 2),
          ),
          _laneLine,
        );
      });
    }
  }

  /// Calls [draw] for each repeat of a pattern that scrolls with the road.
  void _drawRepeating(double height, double period, void Function(double) draw) {
    final start = (_offset % period) - period;
    for (var y = start; y < height; y += period) {
      draw(y);
    }
  }
}
