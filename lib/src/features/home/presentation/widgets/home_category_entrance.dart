import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';

/// A tile's turn in the shelf's entrance: it fades in and pops up to size
/// when its [column] comes up, so the shelf cascades in from its start edge.
/// Columns past the first screenful come in with the last turn, and a tile
/// built after the entrance is over (scrolled into view) shows at once.
///
/// Stateless: every tile reads the shelf's one entrance clock.
class HomeCategoryEntrance extends StatelessWidget {
  const HomeCategoryEntrance({
    super.key,
    required this.animation,
    required this.column,
    required this.child,
  });

  /// The shelf's one-shot entrance clock (0 → 1).
  final Animation<double> animation;

  /// The tile's column on the shelf, counted from the start edge.
  final int column;
  final Widget child;

  /// Columns that get a turn of their own; later ones share the last.
  static const int _turns = 6;

  /// Share of the entrance between two columns' starts.
  static const double _step = 0.08;

  /// Share of the entrance each column takes to come in.
  static const double _span = 1 - _turns * _step;

  static const double _popFrom = 0.6;

  @override
  Widget build(BuildContext context) {
    final start = column.clamp(0, _turns) * _step;
    // Rounding must not push the last turn past the end of the clock.
    final end = math.min(start + _span, 1.0);
    final fade = animation.drive(
      CurveTween(curve: Interval(start, end, curve: AppMotion.signature)),
    );
    // The overshooting curve lands the pop with a small bounce.
    final pop = animation.drive(
      Tween<double>(begin: _popFrom, end: 1).chain(
        CurveTween(curve: Interval(start, end, curve: AppSprings.snappy)),
      ),
    );
    return FadeTransition(
      opacity: fade,
      // A tile waiting for its turn still reads to assistive technology.
      alwaysIncludeSemantics: true,
      child: ScaleTransition(scale: pop, child: child),
    );
  }
}
