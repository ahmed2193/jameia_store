import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../config/theme/app_colors.dart';
import '../design/jameia_cart_mark.dart';

/// Paints [JameiaCartMark] as an icon. [progress] 0 is the one-colour glyph
/// in [ink] with the slats cut out. At 1 it is the app icon itself: the white
/// cart with yellow slats on a brand-green tile with its soft glow. Values in
/// between blend the two. With [hop] the cart jumps once on the way to 1.
class JameiaMarkIconPainter extends CustomPainter {
  const JameiaMarkIconPainter({
    required this.progress,
    required this.ink,
    this.hop = false,
  });

  final double progress;
  final Color ink;
  final bool hop;

  /// Cart width as a share of the side: at rest (like an icon glyph) and on
  /// the tile. The tile value is also the app icon's
  /// (`tool/splash/render_app_icons_test.dart`).
  static const double restCartWidth = 0.88;
  static const double tileCartWidth = 0.6;

  /// The app icon's glow behind the cart: radius and opacity at full size,
  /// and how far above the centre it sits, all as shares of the side.
  static const double glowRadius = 0.62;
  static const double glowOpacity = 0.55;
  static const double glowLift = 0.04;

  /// Tile corner as a share of the side, and the size it grows in from.
  static const double _tileCorner = 0.26;
  static const double _tileStartScale = 0.7;

  /// Peak of the hop as a share of the side.
  static const double _hopHeight = 0.14;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    if (t > 0) _tile(canvas, center, side, t);

    final bounds = JameiaCartMark.bounds;
    final width = side * ui.lerpDouble(restCartWidth, tileCartWidth, t)!;
    final lift = hop ? 4 * t * (1 - t) * _hopHeight * side : 0.0;
    canvas
      ..save()
      ..translate(center.dx, center.dy - lift)
      ..scale(width / bounds.width)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    final cart = Paint()..color = Color.lerp(ink, AppColors.white, t)!;
    canvas.drawPath(JameiaCartMark.bowlCutOut, cart);
    if (t > 0) {
      canvas.drawPath(
        JameiaCartMark.slats,
        Paint()..color = AppColors.accent4.withValues(alpha: t),
      );
    }
    canvas
      ..drawPath(
        JameiaCartMark.outline,
        Paint()
          ..color = cart.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = JameiaCartMark.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(JameiaCartMark.knob, JameiaCartMark.knobRadius, cart);
    for (final wheel in JameiaCartMark.wheels) {
      canvas.drawCircle(wheel, JameiaCartMark.wheelRadius, cart);
    }
    canvas.restore();
  }

  void _tile(Canvas canvas, Offset center, double side, double t) {
    final extent = side * ui.lerpDouble(_tileStartScale, 1, t)!;
    final glowCenter = center - Offset(0, side * glowLift);
    final glow = Color.alphaBlend(
      AppColors.brandDarkBg.withValues(alpha: glowOpacity),
      AppColors.primary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: extent, height: extent),
        Radius.circular(extent * _tileCorner),
      ),
      Paint()
        ..shader = ui.Gradient.radial(glowCenter, side * glowRadius, [
          glow.withValues(alpha: t),
          AppColors.primary.withValues(alpha: t),
        ]),
    );
  }

  @override
  bool shouldRepaint(covariant JameiaMarkIconPainter old) =>
      old.progress != progress || old.ink != ink || old.hop != hop;
}
