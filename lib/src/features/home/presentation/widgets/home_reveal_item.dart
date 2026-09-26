import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';
import 'home_reveal_scope.dart';

/// One card of a block, entering in its turn on the block's reveal clock:
/// it fades up while sliding in from the end edge (a rail) or rising (a
/// grid), a beat after the card before it.
///
/// Only the first [maxAnimated] cards take a turn — the rest are past the
/// screen edge when the block comes in, and show as they are when scrolled
/// to. Outside a block, or once the block is in, a card is simply shown.
class HomeRevealItem extends StatelessWidget {
  const HomeRevealItem({
    super.key,
    required this.index,
    required this.child,
    this.axis = Axis.horizontal,
  });

  /// The card's place in its block.
  final int index;
  final Widget child;

  /// Horizontal: slides in from the end edge. Vertical: rises.
  final Axis axis;

  /// Cards that take a turn; later ones show as they are.
  static const int maxAnimated = 5;

  /// Share of the clock before the first card starts, between two cards'
  /// starts, and each card's own share.
  static const double _lead = 0.2;
  static const double _step = 0.08;
  static const double _span = 0.45;

  /// How far a card travels, as a share of its own size.
  static const double _travel = 0.3;

  @override
  Widget build(BuildContext context) {
    if (index >= maxAnimated) return child;
    final start = _lead + index * _step;
    final turn = HomeRevealScope.revealOf(context).drive(
      CurveTween(
        curve: Interval(
          start,
          math.min(start + _span, 1.0),
          curve: AppMotion.emphasizedDecelerate,
        ),
      ),
    );
    final Offset from;
    if (axis == Axis.vertical) {
      from = const Offset(0, _travel);
    } else {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      from = Offset(rtl ? -_travel : _travel, 0);
    }
    return FadeTransition(
      opacity: turn,
      // A card waiting for its turn still reads to assistive technology.
      alwaysIncludeSemantics: true,
      child: SlideTransition(
        position: turn.drive(Tween<Offset>(begin: from, end: Offset.zero)),
        child: child,
      ),
    );
  }
}
