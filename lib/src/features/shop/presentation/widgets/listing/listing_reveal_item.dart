import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/widgets/shelf_arrival_scope.dart';
import 'listing_reveal_scope.dart';

/// One piece of a listing that comes in with it: it fades in and rises a
/// little on the listing's entrance clock, a beat after the piece before it
/// ([index] 0 first). Only the first [maxAnimated] pieces take part — the
/// ones on screen as a list arrives; the rest are simply there. Touches
/// inside that land a beat later read the arrival ([ShelfArrivalScope]).
class ListingRevealItem extends StatelessWidget {
  const ListingRevealItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  /// A phone shows about this many pieces (the count and two rows of cards)
  /// when a list arrives.
  static const int maxAnimated = 7;

  /// Share of the clock between two pieces, and how long each one takes.
  static const double _step = 0.07;
  static const double _span = 0.5;

  /// How far a piece rises, as a share of its own height.
  static const double _rise = 0.08;

  @override
  Widget build(BuildContext context) {
    if (index >= maxAnimated) return child;
    final start = index * _step;
    // Linear, for the touches inside that ease in their own way.
    final arrival = ListingRevealScope.of(context)
        .drive(CurveTween(curve: Interval(start, start + _span)));
    final eased = arrival.drive(
      CurveTween(curve: AppMotion.emphasizedDecelerate),
    );
    return FadeTransition(
      opacity: eased,
      // A card still fading in is already there for a screen reader.
      alwaysIncludeSemantics: true,
      child: SlideTransition(
        position: eased.drive(
          Tween<Offset>(begin: const Offset(0, _rise), end: Offset.zero),
        ),
        child: ShelfArrivalScope(arrival: arrival, child: child),
      ),
    );
  }
}
