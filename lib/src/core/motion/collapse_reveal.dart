import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'size_fade_transition.dart';

/// THE show / hide of an optional block (docs/motion §9.4 #20): a banner, a
/// notice, a reason line, a bottom bar, an accordion's answer. It opens its
/// height while it fades in over [duration] (default [AppMotion.medium],
/// `signature`) and closes over [reverseDuration] (default [AppMotion.fast],
/// `exit`) — never on mount. While closing it keeps drawing the last child
/// it had while [visible], so the caller may pass an empty child once the
/// data is gone. Closed → the child is not built. Reduced motion → at once.
/// [onClosed] fires once the block is fully closed (a host that makes room
/// for it can give the room back then).
class CollapseReveal extends StatefulWidget {
  const CollapseReveal({
    super.key,
    required this.visible,
    required this.child,
    this.onClosed,
    this.duration = AppMotion.medium,
    this.reverseDuration = AppMotion.fast,
    this.alignment = AlignmentDirectional.topStart,
  });

  final bool visible;
  final Widget child;
  final VoidCallback? onClosed;
  final Duration duration;
  final Duration reverseDuration;

  /// Where the box opens from (see [SizeTransition]).
  final AlignmentGeometry alignment;

  @override
  State<CollapseReveal> createState() => _CollapseRevealState();
}

class _CollapseRevealState extends State<CollapseReveal>
    with SingleTickerProviderStateMixin {
  static const double _open = 1;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
    value: widget.visible ? _open : 0,
  )..addStatusListener(_onStatus);
  // Opens decelerating, closes accelerating (§9.4 #20).
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.signature,
    reverseCurve: AppMotion.exit.flipped,
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
    _controller
      ..duration = widget.duration
      ..reverseDuration = widget.reverseDuration;
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
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }
    return SizeFadeTransition(
      animation: _progress,
      alignment: widget.alignment,
      curve: AppMotion.linear,
      child: ExcludeSemantics(excluding: !widget.visible, child: _shown),
    );
  }
}
