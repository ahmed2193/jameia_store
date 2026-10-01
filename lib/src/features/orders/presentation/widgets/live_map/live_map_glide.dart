import 'dart:math' as math;

import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/courier_progress.dart';

/// How the rider on the live map moves to a new fix: at the feed's own
/// pace between two close fixes ([CourierProgress.glideFrom]); briskly
/// ([AppMotion.slow]) after a longer gap (the map was hidden, the feed
/// stalled); the first fix, or one not after the last, is stepped to
/// (`null`).
abstract final class LiveMapGlide {
  static Duration? between(CourierProgress now, CourierProgress? previous) =>
      now.glideFrom(previous) ??
      (previous != null && now.at.isAfter(previous.at) ? AppMotion.slow : null);

  /// Where a rider gliding [from] → [to] over [length], [done] of the way
  /// through (0 … 1), stands [ahead] from now: on at the glide's pace,
  /// stopping at [to] — where a camera that takes [ahead] to get there
  /// finds them.
  static double metersAhead({
    required double from,
    required double to,
    required double done,
    required Duration length,
    required Duration ahead,
  }) {
    if (length <= Duration.zero) return to;
    final share = math.min(
      1.0,
      done + ahead.inMicroseconds / length.inMicroseconds,
    );
    return from + (to - from) * share;
  }
}
