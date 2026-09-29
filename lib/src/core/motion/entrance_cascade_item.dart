import 'package:flutter/widgets.dart';

import 'entrance_arrival.dart';
import 'entrance_cascade.dart';
import 'motion.dart';

/// One item of an [EntranceCascade]: fades in while rising
/// [AppMotion.entranceRise], `index × AppMotion.staggerStep` after the
/// first, over [AppMotion.medium] / [AppMotion.signature] — once, decided
/// when it mounts, so the widget shape never changes. One controller; the
/// delay is an [Interval] (no Timer: it honours TickerMode — a list that
/// arrives on a hidden tab plays when the tab comes up — and leaves nothing
/// pending in tests). The touches inside read its arrival through
/// [EntranceArrival].
///
/// A closed or spent scope, no scope, `index ≥ maxItems` or motion off → the
/// child as is. Reduced motion → one [AppMotion.fast] fade, no rise, no
/// delay (the whole list fades together).
///
/// [EntranceCascadeItem.single] is the same entrance for one element that
/// has no list around it (a sent bubble, a footer): it plays on mount when
/// [play], [index] steps late.
class EntranceCascadeItem extends StatefulWidget {
  const EntranceCascadeItem({
    super.key,
    required this.index,
    required this.child,
  }) : play = true,
       _single = false;

  const EntranceCascadeItem.single({
    super.key,
    required this.child,
    this.play = true,
    this.index = 0,
  }) : _single = true;

  final int index;
  final Widget child;

  /// [EntranceCascadeItem.single] only: `false` mounts it at rest.
  final bool play;

  final bool _single;

  @override
  State<EntranceCascadeItem> createState() => _EntranceCascadeItemState();
}

class _EntranceCascadeItemState extends State<EntranceCascadeItem>
    with SingleTickerProviderStateMixin {
  static const double _end = 1;

  AnimationController? _controller;
  Animation<double>? _arrival;
  Animation<double>? _eased;
  bool _rises = false;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (!_plays() || MotionGuard.off(context)) return;
    if (MotionGuard.reduced(context)) {
      _start(AppMotion.fast, delay: Duration.zero, curve: AppMotion.linear);
      return;
    }
    _rises = true;
    final steps = widget.index.clamp(0, AppMotion.staggerMaxItems);
    _start(
      AppMotion.medium,
      delay: AppMotion.staggerStep * steps,
      curve: AppMotion.signature,
    );
  }

  bool _plays() {
    if (widget._single) return widget.play;
    final scope = context.findAncestorStateOfType<EntranceCascadeState>();
    return scope != null && scope.isOpen && widget.index < scope.maxItems;
  }

  void _start(
    Duration length, {
    required Duration delay,
    required Curve curve,
  }) {
    final total = delay + length;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    final arrival = controller.drive(
      CurveTween(
        curve: Interval(delay.inMicroseconds / total.inMicroseconds, _end),
      ),
    );
    _arrival = arrival;
    _eased = arrival.drive(CurveTween(curve: curve));
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = _eased;
    final arrival = _arrival;
    if (eased == null || arrival == null) return widget.child;
    // The item's own layer: the fade and the rise only re-composite it.
    final shown = RepaintBoundary(
      child: EntranceArrival(arrival: arrival, child: widget.child),
    );
    return FadeTransition(
      opacity: eased,
      // An item waiting for its turn is already there for a screen reader.
      alwaysIncludeSemantics: true,
      child: _rises
          ? AnimatedBuilder(
              animation: eased,
              child: shown,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  0,
                  (_end - eased.value) * AppMotion.entranceRise,
                ),
                child: child,
              ),
            )
          : shown,
    );
  }
}
