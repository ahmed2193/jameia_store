import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';

/// Rings [child] — the bell glyph — with a few swings that die away when
/// [ringing] turns on, and on first show when it already is: the header's
/// "something new came in". Hung from its top; still under reduced motion.
class HomeBellRing extends StatefulWidget {
  const HomeBellRing({super.key, required this.ringing, required this.child});

  final bool ringing;
  final Widget child;

  @override
  State<HomeBellRing> createState() => _HomeBellRingState();
}

class _HomeBellRingState extends State<HomeBellRing>
    with SingleTickerProviderStateMixin {
  /// The first swing, in radians (about 20°); each one after is smaller.
  static const double _swing = 0.35;
  static const int _swings = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.drawOn,
  );
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    if (widget.ringing) _ring();
  }

  @override
  void didUpdateWidget(covariant HomeBellRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ringing && !oldWidget.ringing) _ring();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ring() {
    if (MotionGuard.reduced(context)) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = _controller.value;
      return Transform.rotate(
        alignment: Alignment.topCenter,
        angle: _swing * (1 - t) * math.sin(t * _swings * 2 * math.pi),
        child: child,
      );
    },
  );
}
