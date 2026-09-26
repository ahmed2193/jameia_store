import 'package:flutter/widgets.dart';

import 'motion.dart';

/// An animated-list row arriving (the gap opens, then the row fades in) or
/// leaving (the row fades, then the gap closes). [animation] is the list's
/// own: 0→1 on insert, 1→0 on removal, 1 for settled rows. The list rebuilds
/// this every frame, so it only uses `drive` — no listener per build. Keep
/// the shape constant (never return the bare child once settled, that would
/// re-mount the row).
class ListItemTransition extends StatelessWidget {
  const ListItemTransition({
    super.key,
    required this.animation,
    required this.child,
    this.leaving = false,
  });

  /// The fade runs over the second half, once the gap is mostly open.
  static const double _fadeFrom = 0.5;
  static const double _fadeTo = 1;

  final Animation<double> animation;
  final Widget child;

  /// A removed row's snapshot: not tappable, not read out.
  final bool leaving;

  @override
  Widget build(BuildContext context) {
    final row = SizeTransition(
      sizeFactor: animation.drive(CurveTween(curve: AppMotion.signature)),
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: const Interval(_fadeFrom, _fadeTo)),
        ),
        alwaysIncludeSemantics: !leaving,
        child: child,
      ),
    );
    return leaving ? IgnorePointer(child: ExcludeSemantics(child: row)) : row;
  }
}
