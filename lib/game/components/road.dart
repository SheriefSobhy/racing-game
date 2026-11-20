import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';

import '../perspective.dart';
import '../racing_game.dart';
import '../world_object.dart';

/// Draws the pseudo-3D road and then every object on it from far to near.
///
/// Performance: the whole road (grass, kerbs, asphalt and lines) is one
/// triangle mesh drawn with a single `drawVertices` call. The vertex
/// buffers are allocated once and reused every frame. Distance fog is baked
/// into the vertex colours, so far-away stripes fade smoothly into the haze
/// instead of shimmering.
class Road extends Component with HasGameReference<RacingGame> {
  Road() : super(priority: 1);

  /// Segments are light/dark in groups of this many.
  static const int _stripeLength = 3;

  // Up to 7 quads per segment, plus the horizon strip. 6 vertices per quad.
  static const int _maxQuads = Perspective.drawSegments * 7 + 1;
  final Float32List _positions = Float32List(_maxQuads * 12);
  final Int32List _colors = Int32List(_maxQuads * 6);
  int _vertexCount = 0;
  Vertices? _vertices;

  final Paint _meshPaint = Paint()..isAntiAlias = false;
  final Paint _hazePaint = Paint();
  final List<WorldObject> _drawList = [];

  // Colours as ARGB ints so they can be mixed without creating objects.
  static const int _grassDark = 0xFF2F7D32;
  static const int _grassLight = 0xFF3D9140;
  static const int _asphaltDark = 0xFF33363E;
  static const int _asphaltLight = 0xFF454851;
  static const int _kerbRed = 0xFFD32F2F;
  static const int _kerbWhite = 0xFFF1F1F1;
  static const int _line = 0xFFF2F2F2;
  static const int _haze = Perspective.hazeColor;

  static const double _hazeDepth = 0.05;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final horizon = game.view.horizonY;
    // Covers tiny far-away objects so they fade in instead of popping up.
    _hazePaint.shader = Gradient.linear(
      Offset(0, horizon - size.y * 0.01),
      Offset(0, horizon + size.y * _hazeDepth),
      const [Color(_haze), Color(0xE6E9C9B6), Color(0x00E9C9B6)],
      const [0.0, 0.3, 1.0],
    );
  }

  @override
  void onRemove() {
    _vertices?.dispose();
    _vertices = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final view = game.view;
    view.update(game.track);

    _buildMesh(view);
    _vertices?.dispose();
    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(_positions, 0, _vertexCount * 2),
      colors: Int32List.sublistView(_colors, 0, _vertexCount),
    );
    _vertices = vertices;
    canvas.drawVertices(vertices, BlendMode.dst, _meshPaint);

    _paintObjects(canvas, view);

    canvas.drawRect(
      Rect.fromLTRB(-40, view.horizonY - view.height * 0.01, view.width + 40,
          view.horizonY + view.height * _hazeDepth),
      _hazePaint,
    );
  }

  // ---------------------------------------------------------------------------
  // Road mesh
  // ---------------------------------------------------------------------------

  void _buildMesh(Perspective view) {
    _vertexCount = 0;

    const rw = Perspective.roadHalfWidth;
    const segLen = Perspective.segmentLength;
    const kerb = rw * 1.13;
    const lane = rw / 3;
    const lineHalf = rw * 0.018;
    const fogStart = 1500.0;
    const fogEnd = Perspective.drawDistance * 0.92;
    final minDz = Perspective.playerDistance * 0.25;
    final left = -40.0;
    final right = view.width + 40;

    var farthestY = view.height;

    for (var n = 0; n < Perspective.drawSegments; n++) {
      final dz1 = view.baseZ + n * segLen - view.cameraZ;
      if (dz1 < minDz) continue;
      final dz2 = dz1 + segLen;

      final s1 = view.focal / dz1;
      final s2 = view.focal / dz2;
      final y1 = view.horizonY + view.cameraHeight * s1;
      final y2 = view.horizonY + view.cameraHeight * s2;
      final x1 = view.centerX + (view.curveXAt(n) - view.cameraX) * s1;
      final x2 = view.centerX + (view.curveXAt(n + 1) - view.cameraX) * s2;
      farthestY = y2;

      // Fog amount at the near and far edge (0 = clear, 1 = full haze).
      final f1 = _fog((dz1 - fogStart) / (fogEnd - fogStart));
      final f2 = _fog((dz2 - fogStart) / (fogEnd - fogStart));

      // When a segment gets thinner than ~2 pixels, blend the light/dark
      // stripes into one average colour so they don't flicker.
      final stripe = ((y1 - y2 - 0.7) / 1.6).clamp(0.0, 1.0);
      final light = ((view.baseIndex + n) ~/ _stripeLength).isEven;

      final grass = _stripeColor(_grassLight, _grassDark, light, stripe);
      final asphalt =
          _stripeColor(_asphaltLight, _asphaltDark, light, stripe);
      final kerbColor = _stripeColor(_kerbWhite, _kerbRed, light, stripe);

      // Grass across the whole width.
      _quad(left, right, y1, left, right, y2, _mix(grass, _haze, f1),
          _mix(grass, _haze, f2));
      // Kerb under the asphalt, then the asphalt.
      _road(x1, s1, y1, x2, s2, y2, -kerb, kerb, kerbColor, f1, f2);
      _road(x1, s1, y1, x2, s2, y2, -rw, rw, asphalt, f1, f2);
      // Solid edge lines.
      final edge = _mix(asphalt, _line, 0.85);
      _road(x1, s1, y1, x2, s2, y2, -rw * 0.95, -rw * 0.92, edge, f1, f2);
      _road(x1, s1, y1, x2, s2, y2, rw * 0.92, rw * 0.95, edge, f1, f2);
      // Dashed lane lines on light segments, fading out with distance.
      if (light && stripe > 0) {
        final dash = _mix(asphalt, _line, stripe);
        _road(x1, s1, y1, x2, s2, y2, -lane - lineHalf, -lane + lineHalf,
            dash, f1, f2);
        _road(x1, s1, y1, x2, s2, y2, lane - lineHalf, lane + lineHalf, dash,
            f1, f2);
      }
    }

    // Haze-coloured strip between the far end of the road and the horizon.
    _quad(left, right, farthestY, left, right, view.horizonY - 1, _haze, _haze);
  }

  /// A strip across the road between world x [a] and [b] for one segment.
  void _road(double x1, double s1, double y1, double x2, double s2, double y2,
      double a, double b, int color, double f1, double f2) {
    _quad(x1 + a * s1, x1 + b * s1, y1, x2 + a * s2, x2 + b * s2, y2,
        _mix(color, _haze, f1), _mix(color, _haze, f2));
  }

  /// Adds a quad as two triangles. Near edge (y1) and far edge (y2) can
  /// have different colours (for fog).
  void _quad(double nearLeft, double nearRight, double y1, double farLeft,
      double farRight, double y2, int nearColor, int farColor) {
    var p = _vertexCount * 2;
    var c = _vertexCount;
    final pos = _positions;
    final col = _colors;

    // Triangle 1: near-left, near-right, far-right.
    pos[p++] = nearLeft;
    pos[p++] = y1;
    pos[p++] = nearRight;
    pos[p++] = y1;
    pos[p++] = farRight;
    pos[p++] = y2;
    // Triangle 2: near-left, far-right, far-left.
    pos[p++] = nearLeft;
    pos[p++] = y1;
    pos[p++] = farRight;
    pos[p++] = y2;
    pos[p++] = farLeft;
    pos[p++] = y2;

    col[c++] = nearColor;
    col[c++] = nearColor;
    col[c++] = farColor;
    col[c++] = nearColor;
    col[c++] = farColor;
    col[c++] = farColor;

    _vertexCount += 6;
  }

  static double _fog(double t) {
    final v = t.clamp(0.0, 1.0);
    return v * (2 - v); // eases out: fog builds up quickly, then levels off
  }

  /// The light or dark stripe colour, blended towards the average of both
  /// when [amount] < 1 (thin, far-away segments).
  static int _stripeColor(int lightColor, int darkColor, bool light,
      double amount) {
    final average = _mix(lightColor, darkColor, 0.5);
    return _mix(average, light ? lightColor : darkColor, amount);
  }

  /// Mixes two opaque ARGB colours without creating objects.
  static int _mix(int a, int b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    final r = ((a >> 16) & 0xFF) + ((((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * t).round();
    final g = ((a >> 8) & 0xFF) + ((((b >> 8) & 0xFF) - ((a >> 8) & 0xFF)) * t).round();
    final bl = (a & 0xFF) + (((b & 0xFF) - (a & 0xFF)) * t).round();
    return 0xFF000000 | (r << 16) | (g << 8) | bl;
  }

  // ---------------------------------------------------------------------------
  // Objects (scenery, cars, coins), drawn far to near
  // ---------------------------------------------------------------------------

  void _paintObjects(Canvas canvas, Perspective view) {
    _drawList
      ..clear()
      ..addAll(game.scenery)
      ..addAll(game.enemies)
      ..addAll(game.coins)
      ..sort(_farFirst);

    final minDz = Perspective.playerDistance * 0.15;
    final maxZ =
        view.cameraZ + Perspective.drawDistance - Perspective.segmentLength;
    for (final obj in _drawList) {
      if (obj.z - view.cameraZ < minDz || obj.z > maxZ) continue;
      obj.paint(canvas, view.project(obj.x, obj.z), view);
    }
  }

  /// Far objects first; ties broken by x so the order never flips between
  /// frames (which would make overlapping objects flicker).
  static int _farFirst(WorldObject a, WorldObject b) {
    final byZ = b.z.compareTo(a.z);
    return byZ != 0 ? byZ : a.x.compareTo(b.x);
  }
}
