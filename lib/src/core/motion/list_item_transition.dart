import 'package:flutter/widgets.dart';

import 'size_fade_transition.dart';

/// An animated-list row arriving (the gap opens, then the row fades in) or
/// leaving (the row fades, then the gap closes). [animation] is the list's
/// own: 0→1 on insert, 1→0 on removal, 1 for settled rows. The list rebuilds
/// this every frame; [SizeFadeTransition] only uses `drive` — no listener
/// per build. Keep the shape constant (never return the bare child once
/// settled, that would re-mount the row).
class ListItemTransition extends StatelessWidget {
  const ListItemTransition({
    super.key,
    required this.animation,
    required this.child,
    this.leaving = false,
  });

  final Animation<double> animation;
  final Widget child;

  /// A removed row's snapshot: not tappable, not read out.
  final bool leaving;

  @override
  Widget build(BuildContext context) {
    final row = SizeFadeTransition(
      animation: animation,
      alwaysIncludeSemantics: !leaving,
      child: child,
    );
    return leaving ? IgnorePointer(child: ExcludeSemantics(child: row)) : row;
  }
}
