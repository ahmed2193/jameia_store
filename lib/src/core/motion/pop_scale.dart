import 'package:flutter/material.dart';

import 'motion.dart';

/// Grow-from-zero POP with overshoot — Jameia's `scale_in` (0→1, 250ms) used by
/// badges, chips, check marks and the cart-count badge. Re-pops whenever
/// [popKey] changes (e.g. cart quantity ticks up). Reduced-motion → pinned at
/// the rest scale (no movement). Use [PopScale.onMount] for a one-shot entrance.
class PopScale extends StatefulWidget {
  const PopScale({
    super.key,
    required this.popKey,
    required this.child,
    this.duration,
    this.curve,
  });

  /// One-shot entrance pop on first build (no re-pop).
  const PopScale.onMount({
    super.key,
    required this.child,
    this.duration,
    this.curve,
  }) : popKey = const Object();

  final Object popKey;
  final Widget child;
  final Duration? duration;
  final Curve? curve;

  @override
  State<PopScale> createState() => _PopScaleState();
}

class _PopScaleState extends State<PopScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.medium,
    value: 1,
  );
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
    if (old.popKey != widget.popKey) _play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionGuard.reduced(context)) return widget.child;
    return ScaleTransition(
      scale:
          Tween<double>(
            begin: AppMotion.popScaleBegin,
            end: AppMotion.popScaleEnd,
          ).animate(
            CurvedAnimation(
              parent: _c,
              curve: widget.curve ?? AppMotion.emphasized,
            ),
          ),
      child: widget.child,
    );
  }
}
