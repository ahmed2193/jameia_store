import 'package:flutter/scheduler.dart';

import 'image_net_activity.dart';

/// "The UI is quiet": the prefetcher's start gate, so a warm-up never takes
/// the UI thread or the network from anything on screen. Resolves never
/// inside the caller's frame, then after polling every [poll] while a screen's
/// image GET is on the wire ([networkBusy]) or a frame is due or being built
/// or an animation ticks (a route transition, a fling, a shimmer), for at most
/// `min(budget, maxDefer)` — a perpetual animation (an ambient loop) must not
/// starve the warm-up. Stops polling as soon as `abort` says nobody waits.
///
/// Timer polling, on purpose: a frame callback would wake the engine.
/// Not `SchedulerBinding.scheduleTask(…, Priority.idle)`: while any ticker
/// runs, its event-loop callback finds the task too low and re-arms
/// `Timer.run` back to back (scheduler/binding.dart `_runTasks`), a busy spin
/// for the whole animation.
class QuietUiGate {
  const QuietUiGate({
    this.poll = const Duration(milliseconds: 100),
    this.maxDefer = const Duration(seconds: 3),
    this.networkBusy = _visibleImageGets,
  });

  final Duration poll;
  final Duration maxDefer;
  final bool Function() networkBusy;

  /// Waits for quiet; completes with the time it deferred.
  Future<Duration> call({Duration? budget, bool Function()? abort}) async {
    await Future<void>.delayed(Duration.zero);
    final Duration cap = budget == null || budget > maxDefer
        ? maxDefer
        : budget;
    final SchedulerBinding b = SchedulerBinding.instance;
    Duration t = Duration.zero;
    while (t < cap && !(abort?.call() ?? false) && (networkBusy() || busy(b))) {
      await Future<void>.delayed(poll);
      t += poll;
    }
    return t;
  }

  /// A frame is due or in progress, or an animation is ticking.
  static bool busy(SchedulerBinding b) =>
      b.schedulerPhase != SchedulerPhase.idle ||
      b.hasScheduledFrame ||
      b.transientCallbackCount > 0;

  static bool _visibleImageGets() => ImageNetActivity.visibleInFlight > 0;
}

/// [gate] for a pool of workers: every waiter joins the ONE wait in progress
/// (a perpetual ticker costs one `maxDefer`, not one per job), charged to a
/// budget [restart] refills to `gate.maxDefer`; once spent, [wait] returns at
/// once. The wait stops polling when no waiter is live any more.
class SharedQuietGate {
  SharedQuietGate(this.gate);

  final QuietUiGate gate;
  final Set<bool Function()> _waiters = <bool Function()>{};
  Future<void>? _open;
  Duration _budget = Duration.zero;

  void restart() => _budget = gate.maxDefer;

  /// Waits for quiet on behalf of a job that wants it while [live] holds.
  Future<void> wait(bool Function() live) async {
    if (_budget <= Duration.zero || !live()) return;
    _waiters.add(live);
    try {
      await (_open ??= _run());
    } finally {
      _waiters.remove(live);
    }
  }

  Future<void> _run() async {
    try {
      final Duration spent = await gate(
        budget: _budget,
        abort: () => !_waiters.any((bool Function() live) => live()),
      );
      _budget -= spent;
    } finally {
      _open = null;
    }
  }
}
