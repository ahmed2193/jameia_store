import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';

/// Subtle "live" pulse for the CURRENT progress step's node — a gentle repeating
/// scale + soft brand-yellow halo so the active step reads as in-progress. When
/// the step is not active (or reduced-motion is on) it renders the child as-is.
class PulseNode extends StatefulWidget {
  const PulseNode({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<PulseNode> createState() => _PulseNodeState();
}

class _PulseNodeState extends State<PulseNode>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState (NOT a lazy `late` initializer): an inactive /
  // reduced-motion node never touches `_c` in initState or build, so a lazy
  // field would first construct the controller inside dispose() — and
  // AnimationController's ctor calls createTicker → TickerMode ancestor lookup,
  // which is illegal once the element is deactivated ("Looking up a deactivated
  // widget's ancestor is unsafe"). Building it up-front keeps dispose safe.
  late final AnimationController _c;

  // Hoisted out of build(): a CurvedAnimation allocated per frame in build would
  // churn the GC every rebuild. Created once here and disposed in dispose().
  late final CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.slow);
    _curved = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulseNode old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || MotionGuard.reduced(context)) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _curved,
        child: widget.child,
        builder: (context, child) {
          final t = _curved.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30 * (1 - t)),
                  blurRadius: 4 + 8 * t,
                  spreadRadius: 1 + 2 * t,
                ),
              ],
            ),
            child: Transform.scale(scale: 1 + 0.06 * t, child: child),
          );
        },
      ),
    );
  }
}
