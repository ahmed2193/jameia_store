import 'package:flutter/widgets.dart';

import '../../../../../core/motion/second_clock_scope.dart';

/// Builds [builder] with the time of the nearest `SecondClockScope` and
/// again each time that clock advances (the tracking page runs one that
/// ticks once a minute, and rests while the page is covered). Outside a
/// scope it builds once with the real time.
class TrackingMinuteBuilder extends StatelessWidget {
  const TrackingMinuteBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  Widget build(BuildContext context) {
    final clock = SecondClockScope.maybeOf(context);
    if (clock == null) return builder(context, DateTime.now());
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) => builder(context, clock.now),
    );
  }
}
