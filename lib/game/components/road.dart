import 'dart:ui';

import 'package:flame/components.dart';

import '../perspective.dart';
import '../racing_game.dart';
import '../world_object.dart';

/// Draws the pseudo-3D road (grass, kerbs, asphalt, lane markings) and then
/// every object on it from far to near, finishing with a haze at the horizon.
///
/// For speed, all stripes of the same colour are collected into one Path,
/// so the whole road costs only a handful of draw calls per frame.
class Road extends Component with HasGameReference<RacingGame> {
  Road() : super(priority: 1);

  // Paths reused every frame.
  final Path _grassLight = Path();
  final Path _kerbBase = Path();
  final Path _kerbRed = Path();
  final Path _asphalt = Path();
  final Path _asphaltLight = Path();
  final Path _edgeLines = Path();
  final Path _laneLines = Path();

  final List<WorldObject> _drawList = [];

  // Paints with screen-space gradients (rebuilt on resize).
  final Paint _grassDarkPaint = Paint();
  final Paint _grassLightPaint = Paint();
  final Paint _asphaltPaint = Paint();
  final Paint _asphaltLightPaint = Paint();
  final Paint _hazePaint = Paint();
  static final Paint _kerbWhitePaint = Paint()..color = const Color(0xFFF1F1F1);
  static final Paint _kerbRedPaint = Paint()..color = const Color(0xFFD32F2F);
  static final Paint _edgeLinePaint = Paint()..color = const Color(0xE6FFFFFF);
  static final Paint _laneLinePaint = Paint()..color = const Color(0xF2FFFFFF);

  /// Segments are light/dark in groups of this many.
  static const int _stripeLength = 3;

  /// How far below the horizon the haze reaches (fraction of screen height).
  static const double _hazeDepth = 0.045;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final view = game.view;
    final top = Offset(0, view.horizonY);
    final bottom = Offset(0, size.y);
    _grassDarkPaint.shader = Gradient.linear(
        top, bottom, const [Color(0xFF7FA867), Color(0xFF2F7D32)]);
    _grassLightPaint.shader = Gradient.linear(
        top, bottom, const [Color(0xFF8DB574), Color(0xFF3B8F3E)]);
    _asphaltPaint.shader = Gradient.linear(
        top, bottom, const [Color(0xFF85878F), Color(0xFF2E3138)]);
    _asphaltLightPaint.shader = Gradient.linear(
        top, bottom, const [Color(0xFF999BA3), Color(0xFF43464F)]);
    _hazePaint.shader = Gradient.linear(
      Offset(0, view.horizonY - size.y * 0.012),
      Offset(0, view.horizonY + size.y * _hazeDepth),
      const [Color(0xCCE9C9B6), Color(0x80E9C9B6), Color(0x00E9C9B6)],
      const [0.0, 0.3, 1.0],
    );
  }

  @override
  void render(Canvas canvas) {
    final view = game.view;
    view.update(game.track);

    _buildRoadPaths(view);

    final w = view.width;
    // Ground (a little wider than the screen so screen shake hides edges).
    canvas.drawRect(
        Rect.fromLTRB(-30, view.horizonY, w + 30, view.height + 30),
        _grassDarkPaint);
    canvas.drawPath(_grassLight, _grassLightPaint);
    canvas.drawPath(_kerbBase, _kerbWhitePaint);
    canvas.drawPath(_kerbRed, _kerbRedPaint);
    canvas.drawPath(_asphalt, _asphaltPaint);
    canvas.drawPath(_asphaltLight, _asphaltLightPaint);
    canvas.drawPath(_edgeLines, _edgeLinePaint);
    canvas.drawPath(_laneLines, _laneLinePaint);

    _paintObjects(canvas, view);

    // Haze where the road meets the horizon.
    canvas.drawRect(
      Rect.fromLTRB(-30, view.horizonY - view.height * 0.012, w + 30,
          view.horizonY + view.height * _hazeDepth),
      _hazePaint,
    );
  }

  void _buildRoadPaths(Perspective view) {
    for (final p in [
      _grassLight,
      _kerbBase,
      _kerbRed,
      _asphalt,
      _asphaltLight,
      _edgeLines,
      _laneLines,
    ]) {
      p.reset();
    }

    const rw = Perspective.roadHalfWidth;
    const segLen = Perspective.segmentLength;
    const kerb = rw * 1.13;
    const lane = rw / 3;
    const lineHalf = rw * 0.018;
    final minDz = Perspective.playerDistance * 0.25;
    final w = view.width;

    for (var n = 0; n < Perspective.drawSegments; n++) {
      final z1 = view.baseZ + n * segLen;
      final dz1 = z1 - view.cameraZ;
      if (dz1 < minDz) continue;
      final dz2 = dz1 + segLen;

      final s1 = view.focal / dz1;
      final s2 = view.focal / dz2;
      final y1 = view.horizonY + view.cameraHeight * s1;
      final y2 = view.horizonY + view.cameraHeight * s2;
      final x1 = view.centerX + (view.curveXAt(n) - view.cameraX) * s1;
      final x2 = view.centerX + (view.curveXAt(n + 1) - view.cameraX) * s2;

      final light = ((view.baseIndex + n) ~/ _stripeLength).isEven;

      void quad(Path path, double a, double b) {
        path
          ..moveTo(x1 + a * s1, y1)
          ..lineTo(x1 + b * s1, y1)
          ..lineTo(x2 + b * s2, y2)
          ..lineTo(x2 + a * s2, y2)
          ..close();
      }

      // Overlap by half a pixel to avoid hairline gaps between segments.
      if (light) _grassLight.addRect(Rect.fromLTRB(-30, y2 - 0.5, w + 30, y1));
      quad(_kerbBase, -kerb, kerb);
      if (!light) {
        quad(_kerbRed, -kerb, -rw * 0.99);
        quad(_kerbRed, rw * 0.99, kerb);
      }
      quad(_asphalt, -rw, rw);
      if (light) quad(_asphaltLight, -rw, rw);
      quad(_edgeLines, -rw * 0.95, -rw * 0.92);
      quad(_edgeLines, rw * 0.92, rw * 0.95);
      if (light) {
        quad(_laneLines, -lane - lineHalf, -lane + lineHalf);
        quad(_laneLines, lane - lineHalf, lane + lineHalf);
      }
    }
  }

  void _paintObjects(Canvas canvas, Perspective view) {
    _drawList
      ..clear()
      ..addAll(game.scenery)
      ..addAll(game.enemies)
      ..addAll(game.coins)
      ..sort((a, b) => b.z.compareTo(a.z)); // far first

    final minDz = Perspective.playerDistance * 0.15;
    final maxZ = view.cameraZ + Perspective.drawDistance - Perspective.segmentLength;
    for (final obj in _drawList) {
      if (obj.z - view.cameraZ < minDz || obj.z > maxZ) continue;
      obj.paint(canvas, view.project(obj.x, obj.z), view);
    }
  }
}
