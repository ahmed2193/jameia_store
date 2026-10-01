import 'dart:ui';

import 'package:flutter/animation.dart';

import 'splash_frame.dart';
import 'splash_layout.dart';
import 'splash_palette.dart';

/// Draws the name as far as the bag has delivered it, and the light that
/// sweeps the finished lockup. A piece is thrown out of the bag's opening:
/// it pops up, then falls on a ballistic arc into its place, growing and
/// turning upright on the way, and squashes as it lands. Pieces are painted
/// before the mark, so they come out of the bag and pass behind it.
abstract final class SplashWordmarkPainting {
  /// A piece leaves the bag this small, turned this far (radians; each piece
  /// turns the other way from the one before).
  static const double launchScale = 0.35;
  static const double launchTurn = 0.45;

  /// The arc's control point rises this far above the opening, as a share of
  /// the drop from the opening to the piece's place: the piece peaks about a
  /// fifth of that above the bag.
  static const double popRise = 0.6;

  /// A piece leaves the opening this share of the way towards its place, so
  /// the pieces come out side by side rather than all from one point.
  static const double launchSpread = 0.2;

  /// A piece is fully opaque this far into its flight.
  static const double opaqueAt = 0.12;

  /// A landing squash also widens a piece by this share of it.
  static const double landingSpread = 0.6;

  /// Half width of the light band sweeping the lockup, its peak opacity, and
  /// the margin of the layer it is clipped to (dp).
  static const double shineHalfWidth = 64;
  static const double shineOpacity = 0.75;
  static const double shineMargin = 12;

  static void paintDeliveries(
    Canvas canvas,
    SplashLayout layout,
    SplashFrame frame,
    SplashPalette palette,
  ) {
    final pieces = layout.wordmark.pieces;
    final bounds = layout.wordmark.pieceBounds;
    final opening = SplashLayout.openingOf(layout.markCenter, layout.markUnit);
    for (var i = 0; i < frame.deliveries.length && i < pieces.length; i++) {
      final (:flight, :squash) = frame.deliveries[i];
      final box = bounds[i];
      final slot = layout.pieceCenter(i);
      final start = Offset(
        opening.dx + (slot.dx - opening.dx) * launchSpread,
        opening.dy,
      );
      final rise = popRise * (slot.dy - start.dy).abs();
      // Over the place itself: the piece moves out sideways early, clear of
      // the handle, then drops in.
      final control = Offset(slot.dx, start.dy - rise);
      final at = _alongArc(start, control, slot, flight);
      final grow = Curves.easeInOutCubic.transform(flight);
      final scale = layout.wordScale * (launchScale + (1 - launchScale) * grow);
      final turn = (i.isEven ? -1 : 1) * launchTurn * (1 - grow);
      final alpha = (flight / opaqueAt).clamp(0.0, 1.0);
      final color = palette.letter;
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(turn)
        ..scale(scale);
      if (squash > 0) {
        // Squash onto the piece's own bottom edge.
        final foot = box.height / 2;
        canvas
          ..translate(0, foot)
          ..scale(1 + landingSpread * squash, 1 - squash)
          ..translate(0, -foot);
      }
      canvas
        ..translate(-box.center.dx, -box.center.dy)
        ..drawPath(
          pieces[i],
          Paint()..color = color.withValues(alpha: color.a * alpha),
        )
        ..restore();
    }
  }

  /// The light band at [shine] (0 → 1) of its sweep across [bounds], lighting
  /// only what is already painted in the current layer (srcATop).
  static void paintShine(
    Canvas canvas,
    Rect bounds,
    double shine,
    SplashPalette palette,
  ) {
    final area = bounds.inflate(shineMargin);
    final x =
        area.left - shineHalfWidth + shine * (area.width + 2 * shineHalfWidth);
    final light = palette.shine;
    canvas.drawRect(
      area,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = Gradient.linear(
          Offset(x - shineHalfWidth, area.top),
          Offset(x + shineHalfWidth, area.bottom),
          [
            light.withValues(alpha: 0),
            light.withValues(alpha: light.a * shineOpacity),
            light.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );
  }

  /// Quadratic Bézier from [a] through [c] to [b] at [t]: with a constant
  /// [t] speed this is a thrown object's parabola.
  static Offset _alongArc(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }
}
