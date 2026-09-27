import 'dart:math' as math;

import 'hero_mark.dart';
import 'hero_mark_painting.dart';

/// The Hero mark at ease, wherever it stays on screen (the sign-in header,
/// an offer card): the cape ripples in the wind — its wave travels from the
/// tie to the tail, [flutters] times per loop — while the bag bobs gently,
/// once per loop. [poseAt] maps a point of the loop (0 → 1) to a pose; the
/// loop starts and ends on the rest pose's cape, so a still mark (reduced
/// motion) is simply `poseAt(0)`.
abstract final class HeroMarkIdle {
  /// Cape ripples per loop.
  static const int flutters = 2;

  /// Height of the bob, in design units.
  static const double bob = 1.6;

  static HeroMarkPose poseAt(double loop) {
    final angle = 2 * math.pi * loop;
    return HeroMarkPose(
      phase: HeroMark.restPhase + flutters * angle,
      lift: bob * math.sin(angle),
    );
  }
}
