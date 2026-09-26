import 'package:flutter/widgets.dart';

import '../responsive/app_size.dart';
import 'entrance_cascade.dart';
import 'motion.dart';

/// One item of an [EntranceCascade]: fades in while rising [_rise], delayed
/// `index × AppMotion.staggerStep`, once — decided when it mounts, so the
/// widget shape never changes. One controller; the delay is an [Interval]
/// (no Timer: it honours TickerMode and leaves nothing pending in tests).
/// Reduced motion, a closed scope or `index ≥ maxItems` → the child as is.
class EntranceCascadeItem extends StatefulWidget {
  const EntranceCascadeItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<EntranceCascadeItem> createState() => _EntranceCascadeItemState();
}

class _EntranceCascadeItemState extends State<EntranceCascadeItem>
    with SingleTickerProviderStateMixin {
  static const double _rise = AppSize.s16;
  static const double _end = 1;

  AnimationController? _controller;
  Animation<double>? _progress;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final scope = context.findAncestorStateOfType<EntranceCascadeState>();
    if (scope == null ||
        !scope.isOpen ||
        widget.index >= scope.maxItems ||
        MotionGuard.reduced(context)) {
      return;
    }
    final delay = AppMotion.staggerStep * widget.index;
    final total = delay + AppMotion.medium;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _progress = controller.drive(
      CurveTween(
        curve: Interval(
          delay.inMicroseconds / total.inMicroseconds,
          _end,
          curve: AppMotion.signature,
        ),
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return widget.child;
    return FadeTransition(
      opacity: progress,
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (_end - progress.value) * _rise),
          child: child,
        ),
      ),
    );
  }
}
