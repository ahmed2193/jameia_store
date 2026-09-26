import 'package:flutter/widgets.dart';

import '../../../../../core/responsive/app_size.dart';
import 'assistant_scroll_anchor.dart';

/// Scroll physics of the (reversed) chat list: keeps the reader's place when
/// the newest reply grows.
///
/// A reversed list pins its bottom edge, so a growing newest row pushes
/// everything above it up. That is right while the reader follows the reply
/// (at the bottom, and the reply still fits on screen). The frame it
/// outgrows the screen, the list stops with the reply's start at the top.
/// From then on — or whenever the reader is scrolled up — the list shifts by
/// the growth ([AssistantScrollAnchor.takePending]) in the same layout pass
/// and nothing the reader looks at moves.
class AssistantAnchoredScrollPhysics extends ScrollPhysics {
  const AssistantAnchoredScrollPhysics({required this.anchor, super.parent});

  final AssistantScrollAnchor anchor;

  /// How close to the bottom still counts as following the reply.
  static const double followThreshold = AppSize.s48;

  @override
  AssistantAnchoredScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      AssistantAnchoredScrollPhysics(
        anchor: anchor,
        parent: buildParent(ancestor),
      );

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final base = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
    final delta = anchor.takePending();
    if (delta == 0 || anchor.suspended) return base;
    final viewport = newPosition.viewportDimension;
    final extent = anchor.newestExtent;
    final wasFollowing =
        oldPosition.pixels <= followThreshold && extent - delta <= viewport;
    // Reading further up: everything on screen stays where it is.
    if (!wasFollowing) return base + delta;
    // Still fits: its newest line stays in view at the bottom.
    if (extent <= viewport) return base;
    // It just outgrew the screen (a burst of cards can do that in one
    // frame): stop with its start at the top, then keep the reader there.
    return base + (extent - viewport);
  }
}
