import 'package:flutter/material.dart';

import 'motion.dart';

/// Idle FLOAT — bobs [child] up by [amplitude] logical pixels and back, over
/// one [AppMotion.floatLoop] period, forever (a hero illustration that feels
/// alive). Paint-only (a `Transform`), wrapped in a `RepaintBoundary`, and the
/// ticker stops with the route (`TickerMode`). Reduced motion → still.
class FloatLoop extends StatefulWidget {
  const FloatLoop({
    super.key,
    required this.child,
    this.amplitude = defaultAmplitude,
    this.period = AppMotion.floatLoop,
  });

  static const double defaultAmplitude = 4;

  final Widget child;
  final double amplitude;
  final Duration period;

  @override
  State<FloatLoop> createState() => _FloatLoopState();
}

class _FloatLoopState extends State<FloatLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.machEaseInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
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
