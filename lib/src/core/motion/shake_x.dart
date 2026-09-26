import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import 'motion.dart';

/// A short horizontal "no" shake — a refused input (an over-long message, a
/// wrong code). Shakes whenever [shakeKey] changes to a new value, never on
/// mount. Reduced motion → no shake, no running controller.
class ShakeX extends StatefulWidget {
  const ShakeX({
    super.key,
    required this.shakeKey,
    required this.child,
    this.amplitude = AppSize.s4,
    this.cycles = 2,
  });

  final Object? shakeKey;
  final Widget child;

  /// Peak offset in logical pixels.
  final double amplitude;

  /// Full left-right swings.
  final int cycles;

  @override
  State<ShakeX> createState() => _ShakeXState();
}

class _ShakeXState extends State<ShakeX> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  @override
  void didUpdateWidget(covariant ShakeX old) {
    super.didUpdateWidget(old);
    if (old.shakeKey == widget.shakeKey || MotionGuard.reduced(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // A sine swing that decays to rest: 0 at both ends.
        final dx =
            math.sin(t * widget.cycles * 2 * math.pi) *
            widget.amplitude *
            (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
