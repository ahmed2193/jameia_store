import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../../core/motion/motion.dart';

/// Timeline maths for the splash choreographies: progress of a beat that
/// starts at [start] ms and lasts [length] ms, and the usual blends.
abstract final class SplashBeat {
  /// 0 before [start], 1 after it ended, eased by [curve] in between.
  static double span(
    double ms,
    double start,
    double length, [
    Curve curve = AppMotion.linear,
  ]) {
    if (length <= 0) return ms >= start ? 1 : 0;
    final t = ((ms - start) / length).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  /// Up and back down over the beat: 0 → 1 → 0 (half a sine), exactly 0
  /// outside it.
  static double arc(double ms, double start, double length) {
    final t = span(ms, start, length);
    return t <= 0 || t >= 1 ? 0 : math.sin(math.pi * t);
  }

  static Offset offset(Offset a, Offset b, double t) =>
      Offset.lerp(a, b, t) ?? b;

  static double lerp(double a, double b, double t) => a + (b - a) * t;
}
