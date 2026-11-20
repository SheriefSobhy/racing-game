import 'dart:math';

/// The road layout: a long loop of segments, each with a "curve" value.
/// 0 = straight, positive = bends right, negative = bends left.
class Track {
  Track({int seed = 7}) {
    _build(Random(seed));
  }

  final List<double> _curves = [];

  int get length => _curves.length;

  /// Curve of the segment with the given (ever-growing) index.
  double curveAt(int segmentIndex) => _curves[segmentIndex % _curves.length];

  void _build(Random random) {
    void straight(int count) {
      for (var i = 0; i < count; i++) {
        _curves.add(0);
      }
    }

    // Smoothly ease into a curve, hold it, then ease out again.
    void curve(int enter, int hold, int leave, double amount) {
      for (var i = 0; i < enter; i++) {
        _curves.add(amount * _ease(i / enter));
      }
      for (var i = 0; i < hold; i++) {
        _curves.add(amount);
      }
      for (var i = 0; i < leave; i++) {
        _curves.add(amount * (1 - _ease(i / leave)));
      }
    }

    straight(80); // a calm start
    var direction = random.nextBool() ? 1.0 : -1.0;
    for (var i = 0; i < 14; i++) {
      final amount = direction * (0.8 + random.nextDouble() * 1.4);
      curve(
        25 + random.nextInt(20),
        30 + random.nextInt(60),
        25 + random.nextInt(20),
        amount,
      );
      straight(30 + random.nextInt(70));
      // Usually alternate direction, sometimes repeat it.
      if (random.nextDouble() < 0.75) direction = -direction;
    }
    straight(40); // the loop joins back to the straight start
  }

  static double _ease(double t) => (1 - cos(t * pi)) / 2;
}
