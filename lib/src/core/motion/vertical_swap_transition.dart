import 'package:flutter/widgets.dart';

import 'motion.dart';

/// THE vertical swap (backlog BX-08, CC-08): one side of an
/// `AnimatedSwitcher` swap in which the new content rises into place from
/// below while the old one leaves ABOVE, both fading — one direction for
/// every ticker, rotating hint, flipped label and rolled digit in the app.
///
/// Use it as the switcher's `transitionBuilder`: [incoming] is whether this
/// side is the new child (compare `child.key` with the current key). The
/// outgoing side's animation runs backwards (1 → 0), so the same builder
/// carries it from its place up and out.
///
/// * The default constructor travels [distance] logical pixels
///   ([AppMotion.entranceRise], 8 dp — the list-entrance rise): a line that
///   changes (a ticker, a hint, a label) moves a touch and fades, it does not
///   scroll a whole line height.
/// * [VerticalSwapTransition.fraction] travels a share of the child's own
///   height — the odometer roll of a digit clipped to its box
///   (`RollingGlyph`).
///
/// [rising] false reverses the direction (a falling number rolls down).
/// Paint-only (a translation and an opacity); the switcher's own duration
/// and curves (through `MotionGuard`) decide the timing, and under reduced
/// motion callers pass a zero [distance] / [share] or skip it for a fade.
class VerticalSwapTransition extends StatelessWidget {
  const VerticalSwapTransition({
    super.key,
    required this.animation,
    required this.incoming,
    required this.child,
    this.distance = AppMotion.entranceRise,
    this.rising = true,
  }) : share = null;

  /// Travels [share] of the child's height instead of a fixed distance.
  const VerticalSwapTransition.fraction({
    super.key,
    required this.animation,
    required this.incoming,
    required this.child,
    required double this.share,
    this.rising = true,
  }) : distance = 0;

  final Animation<double> animation;

  /// This side is the new content (it rises in); false = the old one
  /// (it leaves).
  final bool incoming;
  final Widget child;

  /// How far the content travels, in logical pixels (default constructor).
  final double distance;

  /// How far the content travels, as a share of its height (`.fraction`).
  final double? share;

  /// New content comes from below and old leaves above; false = the other
  /// way round.
  final bool rising;

  /// Where this side sits at the start of its travel: +1 below, −1 above.
  double get _from => (incoming ? 1.0 : -1.0) * (rising ? 1.0 : -1.0);

  @override
  Widget build(BuildContext context) {
    final part = share;
    final Widget moved;
    if (part != null) {
      moved = SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: Offset(0, _from * part), end: Offset.zero),
        ),
        child: child,
      );
    } else {
      final travel = _from * distance;
      moved = AnimatedBuilder(
        animation: animation,
        builder: (context, content) => Transform.translate(
          offset: Offset(0, (1 - animation.value) * travel),
          child: content,
        ),
        child: child,
      );
    }
    return FadeTransition(opacity: animation, child: moved);
  }
}
