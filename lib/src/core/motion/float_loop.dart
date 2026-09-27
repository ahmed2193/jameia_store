import 'package:flutter/material.dart';

import 'motion.dart';

/// Idle FLOAT — bobs [child] up by [amplitude] logical pixels and back, over
/// one [period]: forever (a hero illustration that feels alive), or for
/// [count] legs and then it rests (a hint bubble that should not keep the
/// page drawing). Paint-only (a `Transform`), wrapped in a `RepaintBoundary`,
/// and the ticker stops with the route (`TickerMode`). Reduced motion → still.
class FloatLoop extends StatefulWidget {
  const FloatLoop({
    super.key,
    required this.child,
    this.amplitude = defaultAmplitude,
    this.period = AppMotion.floatLoop,
    this.count,
  });

  static const double defaultAmplitude = 4;

  final Widget child;
  final double amplitude;
  final Duration period;

  /// Legs to play (one leg = up OR back down; an even count ends where it
  /// started), then rest. Null = forever.
  final int? count;

  @override
  State<FloatLoop> createState() => _FloatLoopState();
}

class _FloatLoopState extends State<FloatLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  late final Animation<double> _curve = _controller.drive(
    CurveTween(curve: AppMotion.machEaseInOut),
  );

  /// A counted float already started: it never starts again, whatever
  /// dependency changes later.
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating && !_played) {
      final legs = widget.count;
      final run = _controller.repeat(reverse: true, count: legs);
      if (legs != null) {
        _played = true;
        run.then((_) => _land(legs));
      }
    }
  }

  /// The last frame of a counted float lands a hair past its end; rest
  /// exactly where the legs end (an even count: where it started).
  void _land(int legs) {
    if (!mounted) return;
    _controller.value = legs.isEven
        ? _controller.lowerBound
        : _controller.upperBound;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -widget.amplitude * _curve.value),
          child: child,
        ),
      ),
    );
  }
}
