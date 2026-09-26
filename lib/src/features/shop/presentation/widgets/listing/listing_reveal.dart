import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import 'listing_reveal_scope.dart';

/// The entrance clock of a listing: it runs once each time a list arrives
/// (first load, a new sort or filter — not a pull-to-refresh, which keeps the
/// list on screen), and the result count, the first cards and the empty /
/// error views come in on it ([ListingRevealItem]). A card built again while
/// scrolling reads a finished clock, so nothing replays.
///
/// Under reduced motion or with a screen reader the clock simply stands at
/// the end: everything is there at once.
class ListingReveal extends StatefulWidget {
  const ListingReveal({super.key, required this.settled, required this.child});

  /// Whether the list has arrived (loaded, empty or failed).
  final bool settled;
  final Widget child;

  @override
  State<ListingReveal> createState() => _ListingRevealState();
}

class _ListingRevealState extends State<ListingReveal>
    with SingleTickerProviderStateMixin {
  static const Duration _span = Duration(milliseconds: 900);

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _span,
  );

  /// Mounted on a list that has already arrived: it plays once the motion
  /// settings are known.
  late bool _pending = widget.settled;

  bool get _still =>
      MotionGuard.reduced(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _pending = false;
      _clock.value = 1;
    } else if (_pending) {
      _pending = false;
      _clock.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(ListingReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settled == oldWidget.settled) return;
    if (!widget.settled) {
      // Loading again: the next list starts from the top of the clock.
      _clock.value = 0;
    } else if (_still) {
      _clock.value = 1;
    } else {
      _clock.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListingRevealScope(reveal: _clock, child: widget.child);
}
