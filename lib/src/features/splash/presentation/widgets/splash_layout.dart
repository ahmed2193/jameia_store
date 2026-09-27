import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/design/jameia_cart_mark.dart';
import 'splash_wordmark_geometry.dart';

/// Screen geometry of the splash for one screen [size]: where the cart
/// sits on the launch screen (the native frame) and where the finished
/// lockup — cart "J", name, swoosh — and the tagline end up.
class SplashLayout {
  factory SplashLayout(Size size) {
    final center = size.center(Offset.zero);
    final lockup = SplashWordmarkGeometry.bounds;
    final width = math.min(size.width * lockupWidthFraction, lockupMaxWidth);
    final scale = width / lockup.width;
    final lockupCenter = center.translate(0, -lockupLift);
    final textOrigin = lockupCenter - lockup.center * scale;
    return SplashLayout._(
      size: size,
      center: center,
      scale: scale,
      textOrigin: textOrigin,
      lockupCartCenter: textOrigin + SplashWordmarkGeometry.cartCenter * scale,
      lockupCartUnit: scale * SplashWordmarkGeometry.cartUnit,
      taglineTop: textOrigin.dy + lockup.bottom * scale + taglineGap,
      // The centre's distance from the top-left corner = half the diagonal.
      burstRadius: center.distance,
    );
  }

  const SplashLayout._({
    required this.size,
    required this.center,
    required this.scale,
    required this.textOrigin,
    required this.lockupCartCenter,
    required this.lockupCartUnit,
    required this.taglineTop,
    required this.burstRadius,
  });

  /// Android 12+ shows the launch image (1152 px, read as 4×) in a 288 dp
  /// box centred on the screen; iOS and older Android show the same image at
  /// the same size.
  static const double nativeBox = 288;

  /// Radius of the circle Android 12+ keeps of that box (768 px at 4×).
  static const double nativeSafeRadius = 96;

  /// dp per cart design unit on the launch screen: the cart is about 130 dp
  /// wide and keeps clear of [nativeSafeRadius].
  static const double nativeUnit = 1.4;

  static const double lockupWidthFraction = 0.8;
  static const double lockupMaxWidth = 340;

  /// The lockup sits this far above the centre so it and the tagline under
  /// it read as one centred group.
  static const double lockupLift = 16;
  static const double taglineGap = 22;

  final Size size;
  final Offset center;

  /// dp per font unit of the lockup.
  final double scale;

  /// Screen position of the lockup's font-unit origin (first pen, baseline).
  final Offset textOrigin;

  /// Top of the tagline, under the swoosh.
  final double taglineTop;

  /// Where the cart's centre and size (dp per design unit) end up once it is
  /// the "J" of the name.
  final Offset lockupCartCenter;
  final double lockupCartUnit;

  /// Distance from [center] to a screen corner: the burst disc covers the
  /// whole screen at this radius.
  final double burstRadius;

  /// Where the cart sits on the launch screen: centred, [nativeUnit] big.
  Offset get nativeCartCenter => center;

  /// Centre of the finished lockup (it sits [lockupLift] above the screen
  /// centre).
  Offset get lockupCenter => center.translate(0, -lockupLift);

  /// Where the wheels of the launch-screen cart / the lockup cart touch the
  /// ground (landing rings spread from here).
  Offset get nativeCartGround => groundOf(nativeCartCenter, nativeUnit);
  Offset get lockupCartGround => groundOf(lockupCartCenter, lockupCartUnit);

  static Offset groundOf(Offset cartCenter, double unit) =>
      cartCenter.translate(0, JameiaCartMark.bounds.height / 2 * unit);

  /// Largest distance from the centre the launch-screen cart paints to.
  static double get nativeReach => JameiaCartMark.reach * nativeUnit;
}
