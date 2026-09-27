import 'package:flutter/widgets.dart';

import 'motion.dart';

/// An endless 0 → 1 loop over [period] for a figure that should feel alive
/// while it stays on screen (a mark whose cape ripples, a gentle bob), handed
/// to [builder] — usually straight into a painter's `repaint`, so the loop
/// repaints without rebuilding. It rests at 0 while [running] is off, under
/// reduced motion and while the route is covered (`TickerMode`).
class IdleLoop extends StatefulWidget {
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
  State<IdleLoop> createState() => _IdleLoopState();
}

class _IdleLoopState extends State<IdleLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant IdleLoop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) _loop.duration = widget.period;
    if (oldWidget.running != widget.running ||
        oldWidget.period != widget.period) {
      _sync();
    }
  }

  void _sync() {
    if (widget.running && !_reduced) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _loop);
}
