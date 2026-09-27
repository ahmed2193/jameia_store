import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/design/jameia_cart_mark.dart';
import 'splash_wordmark_glyphs.dart';

/// Where the pieces of the JameiaMart lockup sit, in font units of
/// [SplashWordmarkGlyphs] (y down, baseline at 0, first letter's pen at x 0):
/// the cart standing in for the "J", the leaf dotting the "ı" and the swoosh
/// smiling under the name.
abstract final class SplashWordmarkGeometry {
  /// Font units per cart design unit — the cart stands about two cap heights
  /// tall, as in the logo.
  static const double cartUnit = 14;

  /// Gap between the cart's knob and the first letter.
  static const double cartGap = -120;

  /// How far the bowl dips below the baseline.
  static const double bowlDrop = 30;

  static final double _bowlBottom =
      JameiaCartMark.bowlCenter.dy +
      JameiaCartMark.bowlRadius +
      JameiaCartMark.stroke / 2;

  /// Top-left of the cart's design square inside the lockup.
  static final Offset cartOrigin = Offset(
    -cartGap - JameiaCartMark.bounds.right * cartUnit,
    bowlDrop - _bowlBottom * cartUnit,
  );

  /// Centre of the cart's painted bounds inside the lockup.
  static final Offset cartCenter =
      cartOrigin + JameiaCartMark.bounds.center * cartUnit;

  // ── Leaf over the "ı" ──────────────────────────────────────────────────
  /// Lift of the leaf's stalk above the "ı" stem.
  static const double leafGap = 60;
  static const double leafLength = 360;
  static const double leafHalfWidth = 108;

  /// Lean of the leaf to the right, in radians.
  static const double leafTilt = 0.5;
  static const double leafVeinWidth = 22;

  static const Offset leafBase = Offset(
    SplashWordmarkGlyphs.leafStemX,
    SplashWordmarkGlyphs.leafStemTop - leafGap,
  );

  /// The leaf standing up from its stalk at the origin (tip at y −length).
  static final Path leaf = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-leafHalfWidth * 2, -leafLength * 0.55, 0, -leafLength)
    ..quadraticBezierTo(leafHalfWidth * 2, -leafLength * 0.45, 0, 0)
    ..close();

  /// Midrib, cut out of the leaf in the background colour.
  static const Offset veinStart = Offset(0, -leafLength * 0.14);
  static const Offset veinEnd = Offset(0, -leafLength * 0.7);

  // ── Swoosh under the name ──────────────────────────────────────────────
  static const Offset swooshStart = Offset(-40, 150);
  static const Offset swooshEnd = Offset(3900, 110);
  static const double swooshThickness = 96;
  static const Offset _swooshTopControl = Offset(1650, 430);
  static const Offset _swooshBottomControl = Offset(1850, 600);

  /// A crescent that tapers to a point on the left and ends round on the
  /// right.
  static final Path swoosh = Path()
    ..moveTo(swooshStart.dx, swooshStart.dy)
    ..quadraticBezierTo(
      _swooshTopControl.dx,
      _swooshTopControl.dy,
      swooshEnd.dx,
      swooshEnd.dy,
    )
    ..arcToPoint(
      swooshEnd.translate(0, swooshThickness),
      radius: const Radius.circular(swooshThickness / 2),
    )
    ..quadraticBezierTo(
      _swooshBottomControl.dx,
      _swooshBottomControl.dy,
      swooshStart.dx,
      swooshStart.dy,
    )
    ..close();

  /// The two yellow bands wrapped around the swoosh near its end.
  static const List<double> stripeCenters = [3280, 3440];
  static const double stripeWidth = 88;

  static final Rect swooshBounds = swoosh.getBounds();

  /// Right edge of the swoosh (its round end included).
  static final double swooshRight = swooshEnd.dx + swooshThickness / 2;

  /// Painted extent of the whole lockup: cart, letters, leaf and swoosh.
  static final Rect bounds = Rect.fromLTRB(
    cartOrigin.dx + JameiaCartMark.bounds.left * cartUnit,
    cartOrigin.dy + JameiaCartMark.bounds.top * cartUnit,
    SplashWordmarkGlyphs.width,
    math.max(
      swooshBounds.bottom,
      cartOrigin.dy + JameiaCartMark.bounds.bottom * cartUnit,
    ),
  );
}
