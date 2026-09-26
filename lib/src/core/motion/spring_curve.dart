import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// A physical SPRING usable anywhere a [Curve] is (implicit animations,
/// `CurvedAnimation`): it runs the spring from 0 to 1 at rest and maps the
/// animation's `t` onto the spring's own settle time, so pair it with
/// [duration] — `curve: spring, duration: MotionGuard.duration(ctx,
/// spring.duration)`.
///
/// For SPATIAL motion only (a sliding thumb, a scale pop, a check): an
/// under-damped spring overshoots past 1, which is the point for movement but
/// wrong for colours / opacity (use `AppMotion.fast` + `signature` there).
/// Tokens: `AppMotion.springSnappy` (M3 Expressive fast-spatial, ζ 0.6) and
/// `AppMotion.springCalm` (M3 default-spatial, ζ 0.9).
class SpringCurve extends Curve {
  SpringCurve(this.spring) : settle = _settleSeconds(spring);

  /// Distance (of 1) and speed below which the spring counts as settled.
  static const double _restDistance = 0.005;
  static const double _restVelocity = 0.05;

  /// Search step and cap for the settle time, in seconds.
  static const double _step = 0.001;
  static const double _maxSeconds = 3;
  static const int _microsPerSecond = 1000000;

  final SpringDescription spring;

  /// Seconds the spring needs to settle from rest at 0 to rest at 1.
  final double settle;

  /// [settle] as a [Duration] — the duration to animate this curve over.
  Duration get duration =>
      Duration(microseconds: (settle * _microsPerSecond).round());

  static SpringSimulation _simulation(SpringDescription spring) =>
      SpringSimulation(
        spring,
        0,
        1,
        0,
        tolerance: const Tolerance(
          distance: _restDistance,
          velocity: _restVelocity,
        ),
      );

  static double _settleSeconds(SpringDescription spring) {
    final simulation = _simulation(spring);
    for (var t = _step; t < _maxSeconds; t += _step) {
      if (simulation.isDone(t)) return t;
    }
    return _maxSeconds;
  }

  late final SpringSimulation _sim = _simulation(spring);

  @override
  double transformInternal(double t) => _sim.x(t * settle);
}

/// The app's two springs (Material 3 Expressive motion tokens,
/// `ExpressiveMotionTokens` / `StandardMotionTokens` in androidx).
abstract final class AppSprings {
  /// Fast spatial, damping ratio 0.6 (≈ 320 ms, a little overshoot): a check
  /// popping in, a chip changing shape.
  static final SpringCurve snappy = SpringCurve(
    const SpringDescription(mass: 1, stiffness: 800, damping: 33.94),
  );

  /// Default spatial, damping ratio 0.9 (≈ 210 ms, no visible overshoot):
  /// utilitarian movement — a segmented control's thumb, a typed OTP digit.
  static final SpringCurve calm = SpringCurve(
    const SpringDescription(mass: 1, stiffness: 700, damping: 47.62),
  );

  /// How long a success state (a check on a button) stays before the screen
  /// moves on.
  static const Duration successHold = Duration(milliseconds: 400);
}
