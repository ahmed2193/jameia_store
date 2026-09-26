import 'package:flutter/widgets.dart';

import 'confetti_burst.dart';
import 'confetti_overlay_view.dart';
import 'confetti_painter.dart';
import 'motion.dart';

/// One confetti burst over the WHOLE app (the root overlay): it keeps falling
/// while the route changes under it, then removes itself. For a celebration
/// that ends in a navigation (order placed). Reduced motion or no overlay →
/// nothing (the caller's haptic still confirms).
abstract final class ConfettiOverlay {
  static void play(
    BuildContext context, {
    required List<Color> colors,
    Offset origin = ConfettiBurst.defaultOrigin,
    int count = ConfettiBurst.defaultCount,
  }) {
    if (colors.isEmpty || MotionGuard.reduced(context)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final pieces = ConfettiPiece.scatter(colors: colors, count: count);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ConfettiOverlayView(
        pieces: pieces,
        origin: origin,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}
