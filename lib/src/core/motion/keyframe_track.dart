import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'motion.dart';

/// One stop of a [KeyframeTrack]: at [at] (0–1 of a lap) the value is
/// [value], eased in from the stop before through [curve].
@immutable
class Keyframe {
  const Keyframe(this.at, this.value, [this.curve = AppMotion.machEaseInOut]);

  final double at;
  final double value;
  final Curve curve;
}

/// A value over one lap of a loop (`AmbientLoop`), written as stops: it
/// holds the first stop's value before it and the last one's after it, and
/// between two stops eases from one to the next through the later stop's
/// curve. `const`, so a whole choreography can be data:
///
/// ```dart
/// // Still for the first 10 %, a nod down and back, still again.
/// static const nod = KeyframeTrack([
///   Keyframe(0.1, 0),
///   Keyframe(0.25, 12, AppMotion.signature),
///   Keyframe(0.45, 0),
/// ]);
/// ```
///
/// Drive it with the lap: `lap.drive(nod)`.
class KeyframeTrack extends Animatable<double> {
  const KeyframeTrack(this.frames);

  /// At least one, in order of [Keyframe.at].
  final List<Keyframe> frames;

  @override
  double transform(double t) {
    final first = frames.first;
    if (t <= first.at) return first.value;
    for (var i = 1; i < frames.length; i++) {
      final to = frames[i];
      if (t > to.at) continue;
      final from = frames[i - 1];
      final span = to.at - from.at;
      final progress = span <= 0 ? 1.0 : (t - from.at) / span;
      return from.value +
          (to.value - from.value) * to.curve.transform(progress);
    }
    return frames.last.value;
  }
}
