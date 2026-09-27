import 'package:flutter/widgets.dart';

import 'second_clock.dart';

/// Owns one [SecondClock] for its subtree, so N countdowns on a page cost one
/// timer and one frame per [period], not N unaligned ones. The clock ticks
/// only while `TickerMode.valuesOf(context).enabled` (the page is on stage:
/// a covered route or a placed checkout rests). Reduced motion does NOT stop
/// it — a countdown is information, not motion.
///
/// Descendants find it once, at mount, with [maybeOf] (the `EntranceCascade`
/// precedent — no `InheritedWidget`), then listen to it. [clock] and [period]
/// are read once, when the scope mounts.
class SecondClockScope extends StatefulWidget {
  const SecondClockScope({
    super.key,
    required this.child,
    this.clock = DateTime.now,
    this.period = SecondClock.defaultPeriod,
  });

  final Widget child;

  /// What time it is; a test drives it.
  final DateTime Function() clock;

  /// How often the clock advances.
  final Duration period;

  /// The nearest scope's clock, or null outside any scope.
  static SecondClock? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SecondClockScopeState>()?.clock;

  @override
  State<SecondClockScope> createState() => SecondClockScopeState();
}

class SecondClockScopeState extends State<SecondClockScope> {
  late final SecondClock clock = SecondClock(
    clock: widget.clock,
    period: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    clock.enabled = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
