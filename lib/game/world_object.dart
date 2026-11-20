import 'dart:ui';

import 'perspective.dart';

/// Anything that sits on or beside the road: enemy cars, coins, trees...
/// The road draws all of them from far to near so closer ones cover
/// farther ones.
abstract class WorldObject {
  WorldObject({required this.x, required this.z});

  /// Sideways position in world units (0 = middle of the road).
  double x;

  /// Distance along the road in world units.
  double z;

  /// Set to true to have the object removed.
  bool isRemoved = false;

  /// Draws the object standing on the road at [point].
  void paint(Canvas canvas, ScreenPoint point, Perspective view);
}
