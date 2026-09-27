import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_mark.dart';
import '../design/hero_mark_painting.dart';

/// Paints [HeroMark] as an icon. [progress] 0 is the one-colour glyph in
/// [ink] (the "h" and the cape's gap cut out). At 1 it is the app icon
/// itself: the white bag in its yellow cape on a brand-green tile with a
/// soft glow. Values in between blend the two. With [hop] the bag jumps
/// once on the way to 1.
class HeroMarkIconPainter extends CustomPainter {
  const HeroMarkIconPainter({
    required this.progress,
    required this.ink,
    this.hop = false,
  });

  final double progress;
  final Color ink;
  final bool hop;

  /// Mark width as a share of the side: at rest (like an icon glyph) and on
  /// the tile. The tile value is also the app icon's
  /// (`tool/splash/render_app_icons_test.dart`).
  static const double restMarkWidth = 0.96;
  static const double tileMarkWidth = 0.78;

  /// The app icon's glow behind the mark: radius and opacity at full size,
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
    final width = side * ui.lerpDouble(restMarkWidth, tileMarkWidth, t)!;
    final unit = width / HeroMark.bounds.width;
    final lift = hop ? 4 * t * (1 - t) * _hopHeight * side / unit : 0.0;
    HeroMarkPainting.paint(
      canvas,
      center: center,
      unit: unit,
      colors: HeroMarkColors.lerp(
        HeroMarkColors.mono(ink),
        HeroMarkColors.onBrand,
        t,
      ),
      pose: HeroMarkPose(lift: lift),
    );
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
  bool shouldRepaint(covariant HeroMarkIconPainter old) =>
      old.progress != progress || old.ink != ink || old.hop != hop;
}
