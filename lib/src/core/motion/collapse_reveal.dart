import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Shows / hides an optional block (a banner, a notice, a reason line) by
/// opening / closing its height while it fades — never on mount. While
/// closing it keeps drawing the last child it had while [visible], so the
/// caller may pass an empty child once the data is gone. Closed → the child
/// is not built. Reduced motion → at once. [onClosed] fires once the block is
/// fully closed (a host that makes room for it can give the room back then).
class CollapseReveal extends StatefulWidget {
  const CollapseReveal({
    super.key,
    required this.visible,
    required this.child,
    this.onClosed,
  });

  final bool visible;
  final Widget child;
  final VoidCallback? onClosed;

  @override
  State<CollapseReveal> createState() => _CollapseRevealState();
}

class _CollapseRevealState extends State<CollapseReveal>
    with SingleTickerProviderStateMixin {
  static const double _fadeFrom = 0.5;
  static const double _open = 1;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: widget.visible ? _open : 0,
  )..addStatusListener(_onStatus);
  late final Animation<double> _size = _controller.drive(
    CurveTween(curve: AppMotion.signature),
  );
  late final Animation<double> _opacity = _controller.drive(
    CurveTween(curve: const Interval(_fadeFrom, _open)),
  );
  late Widget _shown = widget.child;

  void _onStatus(AnimationStatus status) {
    // Fully closed: rebuild once so the child is dropped.
    if (!status.isDismissed || !mounted) return;
    setState(() {});
    if (widget.onClosed == null) return;
    // After this frame: a reduced-motion close lands inside the parent's
    // build, which must not be marked dirty from there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.visible) widget.onClosed?.call();
    });
  }

  @override
  void didUpdateWidget(CollapseReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) _shown = widget.child;
    if (widget.visible == oldWidget.visible) return;
    if (MotionGuard.reduced(context)) {
      _controller.value = widget.visible ? _open : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }
    return SizeTransition(
      sizeFactor: _size,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _opacity,
        child: ExcludeSemantics(excluding: !widget.visible, child: _shown),
      ),
    );
  }
}
