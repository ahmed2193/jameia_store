import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';
import 'home_reveal_scope.dart';

/// Builds one frame of a looping touch from the loop's position [t] (0 → 1,
/// or back and forth with `reverse`); [t] = 0 must be the resting pose, and
/// so must [t] = 1 for a loop with a `rest`.
typedef HomeLoopBuilder = Widget Function(
  BuildContext context,
  double t,
  Widget child,
);

/// A small looping touch on a home block — a floating disc, a nudging
/// arrow, a beating badge, a wiggling bag. It runs only while its block is
/// on screen with its tab in front, rests in its [builder]'s resting pose
/// under reduced motion, and repaints nothing but itself.
///
/// With a [rest], each lap is a short burst followed by a pause on a timer:
/// nothing ticks, and no frame is drawn, between two bursts.
class HomeLoop extends StatefulWidget {
  const HomeLoop({
    super.key,
    required this.period,
    required this.builder,
    required this.child,
    this.reverse = false,
    this.phase = 0,
    this.rest = Duration.zero,
  });

  /// One lap (one way, when [reverse]).
  final Duration period;
  final HomeLoopBuilder builder;
  final Widget child;

  /// Back and forth instead of round and round.
  final bool reverse;

  /// Where on the lap (0–1) this one starts, so neighbours keep apart.
  final double phase;

  /// The pause after each lap; none for a loop that never stops moving.
  final Duration rest;

  @override
  State<HomeLoop> createState() => _HomeLoopState();
}

class _HomeLoopState extends State<HomeLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
    value: widget.phase,
  )..addStatusListener(_lapEnded);

  Timer? _pause;
  bool _live = false;

  bool get _rests => widget.rest > Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _live = false;
      _pause?.cancel();
      _controller
        ..stop()
        ..value = 0;
      return;
    }
    final live =
        HomeRevealScope.onScreenOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (live == _live) return;
    _live = live;
    if (!live) {
      // Off screen: holds where it is, and picks up from there.
      _pause?.cancel();
      _controller.stop();
    } else if (_rests) {
      _nextLap();
    } else {
      _controller.repeat(reverse: widget.reverse);
    }
  }

  @override
  void dispose() {
    _pause?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _nextLap() {
    if (!mounted || !_live) return;
    _controller.forward(from: _controller.isCompleted ? 0 : null);
  }

  void _lapEnded(AnimationStatus status) {
    if (!_rests || status != AnimationStatus.completed) return;
    _pause?.cancel();
    _pause = Timer(widget.rest, () {
      _controller.value = 0;
      _nextLap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) =>
            widget.builder(context, _controller.value, child!),
      ),
    );
  }
}
