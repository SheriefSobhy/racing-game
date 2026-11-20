import 'dart:ui';

/// Draws a top-down car (front facing up) inside a box of [size].
/// Shared by the player car and the enemy cars.
void paintCar(
  Canvas canvas,
  Size size, {
  required Color bodyColor,
  required Color stripeColor,
}) {
  final w = size.width;
  final h = size.height;

  // Soft shadow under the car.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.05, w, h),
      Radius.circular(w * 0.3),
    ),
    Paint()..color = const Color(0x40000000),
  );

  // Wheels (sticking out a little on each side).
  final wheelPaint = Paint()..color = const Color(0xFF1B1B1B);
  final wheelW = w * 0.2;
  final wheelH = h * 0.2;
  for (final y in [h * 0.13, h * 0.67]) {
    for (final x in [-w * 0.07, w - wheelW + w * 0.07]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, wheelW, wheelH),
          Radius.circular(wheelW * 0.3),
        ),
        wheelPaint,
      );
    }
  }

  // Body.
  final bodyRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, w, h),
    Radius.circular(w * 0.32),
  );
  canvas.drawRRect(bodyRect, Paint()..color = bodyColor);

  // Racing stripe down the middle.
  canvas.drawRect(
    Rect.fromLTWH(w * 0.42, h * 0.02, w * 0.16, h * 0.96),
    Paint()..color = stripeColor,
  );

  // Windows.
  final glass = Paint()..color = const Color(0xFF263238);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.13, h * 0.27, w * 0.74, h * 0.16),
      Radius.circular(w * 0.12),
    ),
    glass,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.68, w * 0.68, h * 0.11),
      Radius.circular(w * 0.1),
    ),
    glass,
  );

  // Roof with a little highlight.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.44, w * 0.68, h * 0.23),
      Radius.circular(w * 0.1),
    ),
    Paint()..color = bodyColor,
  );
  canvas.drawRect(
    Rect.fromLTWH(w * 0.42, h * 0.44, w * 0.16, h * 0.23),
    Paint()..color = stripeColor,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.29, w * 0.14, h * 0.05),
      Radius.circular(w * 0.03),
    ),
    Paint()..color = const Color(0x55FFFFFF),
  );

  // Headlights (front / top) and tail lights (back / bottom).
  final headlight = Paint()..color = const Color(0xFFFFF59D);
  final taillight = Paint()..color = const Color(0xFFD50000);
  final lightW = w * 0.2;
  final lightH = h * 0.05;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.02, lightW, lightH),
        Radius.circular(lightH / 2)),
    headlight,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.9 - lightW, h * 0.02, lightW, lightH),
        Radius.circular(lightH / 2)),
    headlight,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.93, lightW, lightH * 0.9),
        Radius.circular(lightH / 2)),
    taillight,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.9 - lightW, h * 0.93, lightW, lightH * 0.9),
        Radius.circular(lightH / 2)),
    taillight,
  );
}
