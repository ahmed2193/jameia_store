import 'package:flutter/material.dart';

import 'motion.dart';

/// Grow-from-zero POP with overshoot ([AppSprings.snappy] over
/// [AppMotion.medium]) used by badges, chips, check marks and the cart-count
/// badge. Re-pops whenever
/// [popKey] changes (e.g. cart quantity ticks up). Reduced-motion → pinned at
/// the rest scale (no movement). Use [PopScale.onMount] for a one-shot entrance;
/// [from] is where it grows from (empty-state art: [artFrom], a small settle
/// rather than a grow from nothing).
class PopScale extends StatefulWidget {
  const PopScale({
    super.key,
    required this.popKey,
    required this.child,
    this.duration,
    this.curve,
    this.from = 0,
  });

  /// One-shot entrance pop on first build (no re-pop).
  const PopScale.onMount({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.from = 0,
  }) : popKey = const Object();

  /// The start scale of an empty state's art (docs/motion D13): it settles
  /// in once, then stays still.
  static const double artFrom = 0.9;

  final Object popKey;
  final Widget child;
  final Duration? duration;
  final Curve? curve;

  /// The scale it grows from.
  final double from;

  @override
  State<PopScale> createState() => _PopScaleState();
}

class _PopScaleState extends State<PopScale>
    with SingleTickerProviderStateMixin {
  static const double _to = 1;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.medium,
    value: 1,
  );
  // Built once and re-pointed on a curve change: a CurvedAnimation made in
  // build() registers a listener on the controller on every rebuild.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _c,
    curve: widget.curve ?? AppSprings.snappy,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: widget.from,
    end: _to,
  ).animate(_curve);
  bool _firstPop = false;

  /// Pop the controller — but under reduced motion pin it to the rest scale so
  /// NO controller runs (the OS "remove animations" flag must leave the widget
  /// fully inert, not just visually static).
  void _play() {
    if (MotionGuard.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_firstPop) {
      _firstPop = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant PopScale old) {
    super.didUpdateWidget(old);
    if (old.curve != widget.curve) {
      _curve.curve = widget.curve ?? AppSprings.snappy;
    }
    if (old.popKey != widget.popKey) _play();
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
