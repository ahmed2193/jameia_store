import 'package:flutter/foundation.dart';

import 'hero_shimmer_clock.dart';

/// One image shimmer's membership of the shared [HeroShimmerClock]: attached
/// exactly while [sync] says it is live (so the refcount stays balanced),
/// for [HeroShimmerClock.laps] whole sweeps per run — then [onSpent], and
/// the owner rests on its still frame until [rearm] (back on screen).
class HeroShimmerRun {
  HeroShimmerRun(this.onSpent);

  /// The run's laps are done (called from the clock's tick).
  final VoidCallback onSpent;

  int? _startUs;
  bool _spent = false;

  /// The run's start on the clock; non-null exactly while attached.
  int? get startUs => _startUs;

  /// Attached while [live] and this run is not spent; detached otherwise.
  void sync({required bool live}) {
    final bool want = live && !_spent;
    if (want == (_startUs != null)) return;
    if (want) {
      _startUs = HeroShimmerClock.attach();
      HeroShimmerClock.now.addListener(_onTick);
    } else {
      detach();
    }
  }

  /// The next time it is live is a fresh run.
  void rearm() => _spent = false;

  void detach() {
    if (_startUs == null) return;
    _startUs = null;
    HeroShimmerClock.now.removeListener(_onTick);
    HeroShimmerClock.detach();
  }

  // Every lap of the run done: rest (the band is off the tile at a lap's
  // end, so nothing jumps).
  void _onTick() {
    final int? start = _startUs;
    if (start == null) return;
    if (!HeroShimmerClock.spentAt(start, HeroShimmerClock.now.value)) return;
    _spent = true;
    detach();
    onSpent();
  }
}
