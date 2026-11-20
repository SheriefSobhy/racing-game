import 'dart:typed_data';

import 'track.dart';

/// A point on the screen plus how much the world is scaled there
/// (screen pixels per world unit).
///
/// [Perspective.project] reuses one instance to avoid creating garbage
/// every frame, so read the values straight away.
class ScreenPoint {
  double x = 0;
  double y = 0;
  double scale = 0;
}

/// The pseudo-3D camera. It turns world positions (x across the road,
/// z along the road) into screen positions, including road curves.
///
/// World units: the road is [roadHalfWidth] * 2 wide, segments are
/// [segmentLength] long, and the player is [playerDistance] in front
/// of the camera.
class Perspective {
  static const double segmentLength = 200;
  static const double roadHalfWidth = 1000;
  static const int drawSegments = 160;
  static const double drawDistance = segmentLength * drawSegments;
  static const double playerDistance = 1000;

  /// Haze colour that the far road, grass and sky all fade into.
  static const int hazeColor = 0xFFE9C9B6;

  /// Lane centres in world x: left, middle, right.
  static double laneX(int lane) => (lane - 1) * roadHalfWidth * 2 / 3;

  // Screen setup (recomputed when the screen size changes).
  double width = 1;
  double height = 1;
  double centerX = 0.5;
  double horizonY = 0.4;
  double focal = 1;
  double cameraHeight = 1;

  // Camera position in the world.
  double cameraZ = 0;
  double cameraX = 0;

  // Per-frame curve data: the road's sideways offset at each segment.
  int baseIndex = 0;
  double baseZ = 0;
  final Float64List _curveX = Float64List(drawSegments + 2);

  void resize(double w, double h) {
    width = w;
    height = h;
    centerX = w / 2;
    horizonY = h * 0.42;
    final playerScreenY = h * 0.89;
    // The road at the player's position is a bit wider than the screen
    // so the side lanes still fit comfortably.
    focal = w * 0.55 * playerDistance / roadHalfWidth;
    cameraHeight = (playerScreenY - horizonY) * playerDistance / focal;
  }

  /// Recomputes curve offsets for the visible stretch of road.
  void update(Track track) {
    baseIndex = (cameraZ / segmentLength).floor();
    baseZ = baseIndex * segmentLength;
    final percent = (cameraZ - baseZ) / segmentLength;

    var x = 0.0;
    var dx = -track.curveAt(baseIndex) * percent;
    for (var n = 0; n < _curveX.length; n++) {
      _curveX[n] = x;
      x += dx;
      dx += track.curveAt(baseIndex + n);
    }
  }

  /// Sideways road offset of the near edge of visible segment [n].
  double curveXAt(int n) => _curveX[n];

  /// Sideways road offset at any world z inside the visible range.
  double curveXAtZ(double z) {
    final t = (z - baseZ) / segmentLength;
    final n = t.floor().clamp(0, drawSegments);
    final f = (t - n).clamp(0.0, 1.0);
    return _curveX[n] + (_curveX[n + 1] - _curveX[n]) * f;
  }

  final ScreenPoint _point = ScreenPoint();

  /// Projects a point on the road surface to the screen.
  /// The returned object is reused by the next call.
  ScreenPoint project(double worldX, double worldZ) {
    final dz = worldZ - cameraZ;
    final scale = focal / dz;
    _point
      ..scale = scale
      ..x = centerX + (worldX + curveXAtZ(worldZ) - cameraX) * scale
      ..y = horizonY + cameraHeight * scale;
    return _point;
  }
}
