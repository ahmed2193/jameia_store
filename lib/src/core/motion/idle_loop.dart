import 'package:flutter/widgets.dart';

import 'ambient_loop.dart';
import 'motion.dart';

/// An idle 0 → 1 loop over [period] for a figure that should feel alive
/// when it comes on screen (a mark whose cape ripples, a gentle bob): an
/// [AmbientLoop] preset (D14), handed to [builder] — usually straight into
/// a painter's `repaint`, so the loop repaints without rebuilding. Whole
/// laps for at most [AppMotion.ambientBudget] per appearance; it rests at 0
/// while [running] is off, off screen, under reduced motion, with a screen
/// reader and while the route is covered.
class IdleLoop extends StatelessWidget {
  const IdleLoop({
    super.key,
    required this.builder,
    this.period = AppMotion.floatLoop,
    this.running = true,
  });

  final Widget Function(BuildContext context, Animation<double> loop) builder;
  final Duration period;
  final bool running;

  @override
  Widget build(BuildContext context) => AmbientLoop(
    period: period,
    active: running,
    builder: (context, loop, _) => builder(context, loop),
  );
}
