import 'dart:ui';

import '../perspective.dart';
import '../world_object.dart';
import 'car_painter.dart';

/// A slower car driving ahead in one of the lanes. Hitting it ends the game.
class EnemyCar extends WorldObject {
  EnemyCar({required this.lane, required super.z, required this.color})
      : super(x: Perspective.laneX(lane));

  /// Car width in world units (a lane is about 667 wide).
  static const double worldWidth = 380;

  /// Body colours to pick from.
  static const colors = [
    Color(0xFF1E88E5), // blue
    Color(0xFFFDD835), // yellow
    Color(0xFF8E24AA), // purple
    Color(0xFFFB8C00), // orange
    Color(0xFF00ACC1), // teal
    Color(0xFFEC407A), // pink
    Color(0xFFECEFF1), // white
    Color(0xFF43A047), // green
  ];

  final int lane;
  final Color color;

  @override
  void paint(Canvas canvas, ScreenPoint point, Perspective view) {
    final pixelWidth = worldWidth * point.scale;
    if (pixelWidth < 2) return; // too far away to see
    canvas.save();
    canvas.translate(point.x, point.y);
    canvas.scale(pixelWidth);
    CarPainter.paintCar(
      canvas,
      body: color,
      lean: (point.x - view.centerX) / view.width * 2,
    );
    canvas.restore();
  }
}
