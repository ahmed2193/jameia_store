import 'dart:math' as math;

/// The mascot's small gestures as curves of their progress `t` (`0..1`),
/// each back at rest when it ends: its sprout waving hello, and a wink.
abstract final class AssistantMascotGesture {
  static const double _waveReach = 0.8;
  static const double _waveTurns = 2;

  /// The sprout waving side to side, settling as it ends.
  static double wave(double t) =>
      math.sin(t * math.pi * 2 * _waveTurns) * _waveReach * (1 - t);

  /// One eye closing and opening again.
  static double wink(double t) => math.sin(math.pi * t);
}
