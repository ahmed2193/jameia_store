import 'package:flutter/widgets.dart';

import 'second_clock.dart';

/// The ticking half of every countdown, written once (docs/motion CC-11):
/// which [SecondClock] a countdown reads, listening to it only while the
/// countdown runs, letting go otherwise, and never after `dispose`. The
/// looks (the home strip's flip text, the red boxes of `CountdownDigits`)
/// and when each one runs stay theirs: they call [followClock] once, then
/// [listenToClock] with whether they run now, and get [onClockTick] on
/// every tick while they listen.
mixin SecondClockFollower<T extends StatefulWidget> on State<T> {
  SecondClock? _followed;
  bool _listening = false;

  /// The clock this countdown reads, once [followClock] gave one.
  SecondClock? get followedClock => _followed;

  /// The time as the clock sees it (the real time without a clock).
  DateTime get clockNow => _followed?.now ?? DateTime.now();

  /// How long until [endsAt] by the clock; never negative.
  Duration timeLeftUntil(DateTime endsAt) {
    final left = endsAt.difference(clockNow);
    return left.isNegative ? Duration.zero : left;
  }

  /// Reads [clock] from now on. The first clock given wins: a countdown
  /// never moves to another clock mid-life.
  void followClock(SecondClock? clock) => _followed ??= clock;

  /// Listens while [run], lets go otherwise.
  void listenToClock(bool run) {
    final clock = _followed;
    if (run && !_listening && clock != null) {
      clock.addListener(onClockTick);
      _listening = true;
    } else if (!run) {
      stopListeningToClock();
    }
  }

  /// Lets go of the clock (at zero, off screen, disposed).
  void stopListeningToClock() {
    if (!_listening) return;
    _followed?.removeListener(onClockTick);
    _listening = false;
  }

  /// One tick of the clock while this countdown listens.
  void onClockTick();

  @override
  void dispose() {
    stopListeningToClock();
    super.dispose();
  }
}
