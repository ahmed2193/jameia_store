import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';

/// Depth for the product photos: while the sheet rides up over them they
/// drift up at a fraction of the scroll speed, so the page reads as a sheet
/// sliding over a photo. The drift never opens a gap — the photos' top stays
/// above the page's and their bottom under the sheet. Follows [scroll] (the
/// page list's offset) by moving its child as a layer: the pager never
/// rebuilds or repaints for it. Still under reduced motion.
class PdpGalleryDepth extends StatelessWidget {
  const PdpGalleryDepth({super.key, required this.scroll, required this.child});

  /// The page list's scroll offset.
  final ValueListenable<double> scroll;
  final Widget child;

  /// The share of the scroll the photos lag behind: they move up at 60 % of
  /// the page's speed.
  static const double lag = 0.4;

  @override
  Widget build(BuildContext context) {
    // Same tree either way, so a motion setting flip never remounts the
    // pager.
    final share = MotionGuard.reduced(context) ? 0.0 : lag;
    return ValueListenableBuilder<double>(
      valueListenable: scroll,
      child: RepaintBoundary(child: child),
      builder: (context, pixels, child) => Transform.translate(
        // Only once the page moves up: a pull past the top is the
        // platform's own stretch or bounce.
        offset: Offset(0, pixels > 0 ? pixels * share : 0),
        child: child,
      ),
    );
  }
}
