import 'dart:math' as math;

/// The mascot's happy hop as curves of its progress `t` (`0..1`): crouch,
/// spring up stretched, fall, land squashed, settle — the classic squash &
/// stretch arc, laughing and shaking its sprout on the way.
abstract final class AssistantMascotHop {
  static const double _crouchEnd = 0.15;
  static const double _apex = 0.45;
  static const double _landAt = 0.75;
  static const double _settleAt = 0.88;

  static const double _crouch = 0.6;
  static const double _stretch = -0.5;
  static const double _land = 0.45;
  static const double _swayAmount = 0.9;
  static const double _swayTurns = 2;

  /// How high the body is, `0..1` of the hop height.
  static double lift(double t) {
    if (t <= _crouchEnd || t >= _landAt) return 0;
    if (t <= _apex) {
      final up = (t - _crouchEnd) / (_apex - _crouchEnd);
      return 1 - math.pow(1 - up, 2).toDouble();
    }
    final down = (t - _apex) / (_landAt - _apex);
    return 1 - down * down;
  }

  /// Squash (> 0) and stretch (< 0) of the body.
  static double squash(double t) {
    if (t <= _crouchEnd) return _crouch * (t / _crouchEnd);
    if (t <= _apex) {
      return _lerp(_crouch, _stretch, (t - _crouchEnd) / (_apex - _crouchEnd));
    }
    if (t <= _landAt) {
      return _lerp(_stretch, 0, (t - _apex) / (_landAt - _apex));
    }
    if (t <= _settleAt) {
      return _land * math.sin(math.pi * (t - _landAt) / (_settleAt - _landAt));
    }
    return 0;
  }

  /// The sprout shaking, fading out as the hop ends.
  static double sway(double t) =>
      math.sin(t * math.pi * 2 * _swayTurns) * _swayAmount * (1 - t);

  /// Laughing and sparkling: up fast, then easing off.
  static double joy(double t) => math.sin(math.pi * t);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
