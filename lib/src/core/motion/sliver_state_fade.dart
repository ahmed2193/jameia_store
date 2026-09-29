import 'package:flutter/widgets.dart';

import 'motion.dart';

/// A sliver whose content swaps with its screen state — the bones, the
/// cards, an empty or an error plate. The FIRST arrival is the list's
/// `EntranceCascade`'s to play; every later swap (a new sort or filter
/// brings the bones back, then the new cards; a retry brings the list)
/// fades the new content in over [AppMotion.fast] instead of snapping (App
/// A §45). Slivers cannot overlap, so the old content leaves at once and
/// the fade stays short. Reduced motion → the swap is instant.
class SliverStateFade extends StatefulWidget {
  const SliverStateFade({
    super.key,
    required this.stateKey,
    required this.arrived,
    required this.sliver,
  });

  /// Which state the sliver shows; a new value is a swap.
  final Object stateKey;

  /// This state is an arrival (the list, its empty or error plate) rather
  /// than the bones: once one has shown, later swaps fade.
  final bool arrived;

  final Widget sliver;

  @override
  State<SliverStateFade> createState() => _SliverStateFadeState();
}

class _SliverStateFadeState extends State<SliverStateFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    value: 1,
  );
  late final Animation<double> _opacity = _fade.drive(
    CurveTween(curve: AppMotion.signature),
  );

  /// An arrival has shown: swaps from now on fade. Read in [initState], not
  /// lazily: a lazy read would first happen with the NEXT widget.
  late bool _hasArrived;

  @override
  void initState() {
    super.initState();
    _hasArrived = widget.arrived;
  }

  @override
  void didUpdateWidget(SliverStateFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stateKey != oldWidget.stateKey) {
      if (_hasArrived && !MotionGuard.reduced(context)) {
        _fade.forward(from: 0);
      } else {
        _fade.value = 1;
      }
    }
    if (widget.arrived) _hasArrived = true;
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SliverFadeTransition(opacity: _opacity, sliver: widget.sliver);
}
