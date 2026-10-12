import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../motion/motion.dart';

/// The ONE ticker behind every image shimmer (`HeroImageShimmer`): it runs
/// only while at least one live shimmer is attached, and [now] — the
/// ticker's running time — moves every painter at once, with no rebuild.
/// Each shimmer counts its sweep from its own [attach] time ([phaseAt]), so
/// its band always enters from the start edge, whoever else is sweeping.
///
/// A raw [Ticker]: `TickerMode` does not mute it, so a shimmer ATTACHES only
/// while its own `TickerMode` is on (a hidden tab or a covered route detach
/// it), the motion is not reduced and its sweep budget ([laps]) is not
/// spent; the refcount does the rest.
abstract final class HeroShimmerClock {
  /// One sweep: the skeleton shimmer's period.
  static const Duration period = AppMotion.shimmer;

  /// Whole sweeps a shimmer runs before it rests on its still frame: as
  /// many as fit the ambient budget (no endless loop, WCAG 2.2.2's five
  /// seconds). The tile's next attempt, or its coming back on screen,
  /// starts a new run.
  static final int laps =
      AppMotion.ambientBudget.inMicroseconds ~/ period.inMicroseconds;

  static final ValueNotifier<int> _nowUs = ValueNotifier<int>(0);
  static Ticker? _ticker;
  static int _attached = 0;

  /// The ticker's running time in µs, ticking every frame while it runs.
  static ValueListenable<int> get now => _nowUs;

  /// Whether the ticker is running.
  static bool get isTicking => _ticker?.isActive ?? false;

  /// Live shimmers attached (tests only).
  @visibleForTesting
  static int get debugAttached => _attached;

  /// Joins the ticker (starting it for the first shimmer); returns the
  /// shimmer's start on [now].
  static int attach() {
    if (_attached++ == 0) {
      _nowUs.value = 0;
      _ticker = Ticker(_tick, debugLabel: 'HeroShimmerClock')..start();
    }
    return _nowUs.value;
  }

  static void detach() {
    if (_attached == 0) return;
    if (--_attached == 0) {
      _ticker?.dispose();
      _ticker = null;
    }
  }

  /// Where a sweep started at [startUs] is, 0 → 1 (linear, like the
  /// skeleton's), at [nowUs].
  static double phaseAt(int startUs, int nowUs) {
    final int periodUs = period.inMicroseconds;
    final int run = nowUs - startUs;
    return run <= 0 ? 0 : (run % periodUs) / periodUs;
  }

  /// Whether a sweep started at [startUs] has run all its [laps] by [nowUs].
  static bool spentAt(int startUs, int nowUs) =>
      nowUs - startUs >= laps * period.inMicroseconds;

  static void _tick(Duration elapsed) => _nowUs.value = elapsed.inMicroseconds;
}
