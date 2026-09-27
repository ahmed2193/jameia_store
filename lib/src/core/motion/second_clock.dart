import 'dart:async';

import 'package:flutter/foundation.dart';

/// One wall clock for every countdown under a `SecondClockScope`: [now]
/// advances on whole [period]s and notifies once per period — ONE [Timer] for
/// the whole page, and only while (a) someone listens and (b) [enabled]. Each
/// tick is aligned to the next [period] boundary, so every countdown flips in
/// the same frame. Re-enabling reads the real time at once (no stale second)
/// and tells the listeners when it moved.
///
/// Not a widget: `SecondClockScope` owns one and enables it only while its
/// page is on stage (`TickerMode`).
class SecondClock extends ChangeNotifier {
  SecondClock({DateTime Function()? clock, this.period = defaultPeriod})
    : assert(period > Duration.zero, 'a clock needs a positive period'),
      _clock = clock ?? DateTime.now {
    _now = _floor(_clock());
  }

  /// A countdown's cadence: once a second.
  static const Duration defaultPeriod = Duration(seconds: 1);

  /// How often [now] advances (a second for countdowns, a minute for a
  /// "arrives around 5:55 PM" line).
  final Duration period;

  final DateTime Function() _clock;
  late DateTime _now;
  bool _enabled = true;
  Timer? _timer;

  /// The current time, floored to the [period]. While the clock runs every
  /// reader in a frame sees the same value; while it rests it reads the real
  /// time, so a widget mounting on a resting clock is never stale.
  DateTime get now {
    if (_timer == null) _now = _floor(_clock());
    return _now;
  }

  bool get enabled => _enabled;

  /// Whether the clock may tick. The scope sets it from `TickerMode`; turning
  /// it back on reads the real time at once and notifies the listeners.
  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    if (value) {
      // The listeners last drew the time the clock stopped at; show them
      // the real one in this frame (the scope's descendants rebuild in it).
      _now = _floor(_clock());
      notifyListeners();
    }
    _sync();
  }

  /// A timer is pending (the clock is running).
  @visibleForTesting
  bool get debugIsRunning => _timer != null;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _sync();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _sync() {
    final run = _enabled && hasListeners;
    if (run && _timer == null) {
      _now = _floor(_clock());
      _arm();
    } else if (!run) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _arm() {
    final step = period.inMicroseconds;
    final into = _clock().microsecondsSinceEpoch % step;
    _timer = Timer(Duration(microseconds: step - into), _tick);
  }

  void _tick() {
    _timer = null;
    final fresh = _floor(_clock());
    final moved = fresh != _now;
    _now = fresh;
    if (moved) notifyListeners();
    // After the notification: a countdown that reached zero removed itself
    // during it, and the listener count is only settled once it is over.
    _sync();
  }

  DateTime _floor(DateTime at) {
    final micros = at.microsecondsSinceEpoch;
    return DateTime.fromMicrosecondsSinceEpoch(
      micros - micros % period.inMicroseconds,
      isUtc: at.isUtc,
    );
  }
}
