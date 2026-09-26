import 'package:flutter/widgets.dart';

import '../../config/theme/app_spacing.dart';
import '../motion/motion.dart';
import 'back_to_top_button.dart';

/// Puts a "back to the top" button in the bottom corner of a long vertical
/// list ([child]): it pops up once the customer is a screen and a half down
/// and takes them back up in one glide (a jump under reduced motion).
///
/// Follows the list through its own scroll notifications, so it works under
/// a route whose primary scroll controller is shared with other lists (the
/// shell's tabs all live in one route), keeps the list's own controller (and
/// its status-bar tap) untouched, and ignores nested horizontal rails.
class BackToTopOverlay extends StatefulWidget {
  const BackToTopOverlay({
    super.key,
    required this.child,
    this.margin = AppSpacing.s16,
  });

  final Widget child;

  /// Distance of the button from the end and bottom edges.
  final double margin;

  @override
  State<BackToTopOverlay> createState() => _BackToTopOverlayState();
}

class _BackToTopOverlayState extends State<BackToTopOverlay> {
  /// How many screens down the list the button comes up.
  static const double _screensDown = 1.5;

  /// The list the button takes back up, from its latest notification.
  ScrollPosition? _list;
  bool _shown = false;

  bool _follow(Notification notification) {
    final (metrics, depth, from) = switch (notification) {
      ScrollNotification(:final metrics, :final context) => (
        metrics,
        notification.depth,
        context,
      ),
      ScrollMetricsNotification(:final metrics, :final context) => (
        metrics,
        notification.depth,
        context,
      ),
      _ => (null, 0, null),
    };
    // Only the list itself, not a rail inside it.
    if (metrics == null || depth != 0 || metrics.axis != Axis.vertical) {
      return false;
    }
    if (from != null) _list = Scrollable.maybeOf(from)?.position ?? _list;
    final shown = metrics.pixels > metrics.viewportDimension * _screensDown;
    if (shown != _shown) setState(() => _shown = shown);
    return false;
  }

  void _toTop() {
    final list = _list;
    if (list == null || !list.hasPixels) return;
    if (MotionGuard.reduced(context)) {
      list.jumpTo(0);
      return;
    }
    list.animateTo(
      0,
      duration: AppMotion.sheetLarge,
      curve: AppMotion.emphasizedDecelerate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<Notification>(
          onNotification: _follow,
          child: widget.child,
        ),
        PositionedDirectional(
          end: widget.margin,
          bottom: widget.margin,
          child: BackToTopButton(shown: _shown, onTap: _toTop),
        ),
      ],
    );
  }
}
