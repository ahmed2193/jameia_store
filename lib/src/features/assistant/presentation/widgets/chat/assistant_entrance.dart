import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';

/// Plays ONE entrance when first mounted — fade + slide (+ optional scale) —
/// and is inert afterwards: a rebuild or the `message_end` swap never replays
/// it, and [animate] `false` mounts the child at rest (history, recycled
/// rows). The x offset follows the reading direction; reduced motion → at
/// rest, no controller running.
class AssistantEntrance extends StatefulWidget {
  const AssistantEntrance({
    super.key,
    required this.child,
    this.animate = true,
    this.beginOffset = defaultOffset,
    this.beginScale = 1,
    this.delay = Duration.zero,
    this.curve = AppMotion.emphasizedDecelerate,
    this.alignment = AlignmentDirectional.center,
  });

  static const Offset defaultOffset = Offset(0, 0.08);

  final Widget child;
  final bool animate;

  /// In child sizes; x is flipped for right-to-left.
  final Offset beginOffset;
  final double beginScale;
  final Duration delay;
  final Curve curve;

  /// The point the scale grows from (e.g. the end edge for a sent bubble).
  final AlignmentGeometry alignment;

  @override
  State<AssistantEntrance> createState() => _AssistantEntranceState();
}

class _AssistantEntranceState extends State<AssistantEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: widget.animate ? 0 : 1,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _c,
    curve: widget.curve,
  );
  // Built once: the begin values are fixed for the life of the entrance.
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: widget.beginOffset,
    end: Offset.zero,
  ).animate(_curved);
  late final Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1,
  ).animate(_curved);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_c.isCompleted) return;
    if (MotionGuard.reduced(context)) {
      _c.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _curved.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        textDirection: Directionality.of(context),
        position: _offset,
        child: ScaleTransition(
          alignment: widget.alignment.resolve(Directionality.of(context)),
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
