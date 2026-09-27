import 'dart:ui';

import '../../../../config/theme/app_colors.dart';

/// The colours of one splash scene: the white logo on the brand green of the
/// launch screen ([onBrand]) or the full-colour logo on white ([onWhite],
/// what the burst reveal turns the screen into).
class SplashPalette {
  const SplashPalette._({
    required this.background,
    required this.cartInk,
    required this.cartFill,
    required this.slat,
    required this.letterInk,
    required this.letterAccent,
    required this.swoosh,
    required this.stripe,
    required this.leaf,
    required this.speedLine,
    required this.shadow,
    required this.bottle,
    required this.fruit,
    required this.greens,
    required this.glow,
    required this.aurora,
    required this.ripple,
    required this.confetti,
    required this.shine,
    required this.letterFlash,
  });

  /// White logo on the brand green — the native launch screen's colours.
  static const SplashPalette onBrand = SplashPalette._(
    background: AppColors.primary,
    cartInk: AppColors.white,
    cartFill: AppColors.white,
    slat: AppColors.accent4,
    letterInk: AppColors.white,
    letterAccent: AppColors.white,
    swoosh: AppColors.white,
    stripe: AppColors.accent4,
    leaf: AppColors.accent4,
    speedLine: AppColors.subtitleOverlay,
    shadow: AppColors.primaryDark,
    bottle: AppColors.white,
    fruit: AppColors.accent3,
    greens: AppColors.brandDeep,
    glow: AppColors.brandDarkBg,
    aurora: [AppColors.brandDarkBg, AppColors.accent4, AppColors.brandDeep],
    ripple: AppColors.white,
    confetti: [
      AppColors.accent4,
      AppColors.white,
      AppColors.brandLightBg,
      AppColors.accent3,
    ],
    shine: AppColors.white,
    letterFlash: AppColors.accent4,
  );

  /// The logo's own colours on white: deep green "Jameia", green "Mart",
  /// orange slats and stripes.
  static const SplashPalette onWhite = SplashPalette._(
    background: AppColors.white,
    cartInk: AppColors.brandDeep,
    cartFill: AppColors.white,
    slat: AppColors.accent3,
    letterInk: AppColors.brandDeep,
    letterAccent: AppColors.primary,
    swoosh: AppColors.primary,
    stripe: AppColors.accent3,
    leaf: AppColors.primary,
    speedLine: AppColors.brandLightBg,
    shadow: AppColors.overlayDivider,
    bottle: AppColors.brandLightBg,
    fruit: AppColors.accent3,
    greens: AppColors.primary,
    glow: AppColors.brandLightBg,
    aurora: [
      AppColors.brandLightBg,
      AppColors.accent4Light,
      AppColors.accent2Light,
    ],
    ripple: AppColors.primary,
    confetti: [
      AppColors.primary,
      AppColors.accent3,
      AppColors.accent4,
      AppColors.brandDeep,
    ],
    shine: AppColors.white,
    letterFlash: AppColors.accent3,
  );

  final Color background;

  /// Handle, stem, bowl outline, knob and wheels.
  final Color cartInk;

  /// Inside of the basket bowl.
  final Color cartFill;
  final Color slat;

  /// "ameia" — and [letterAccent] for "Mart".
  final Color letterInk;
  final Color letterAccent;
  final Color swoosh;
  final Color stripe;
  final Color leaf;
  final Color speedLine;

  /// Ground shadow under the hopping cart (drawn translucent).
  final Color shadow;

  /// The groceries of the basket scene.
  final Color bottle;
  final Color fruit;
  final Color greens;

  /// Soft light behind the logo.
  final Color glow;

  /// Colours of the slow blobs drifting in the background.
  final List<Color> aurora;

  /// Landing and tap rings.
  final Color ripple;

  /// Pieces of the landing burst.
  final List<Color> confetti;

  /// The light that sweeps the finished name.
  final Color shine;

  /// Tint a letter springs in with before it settles to its colour.
  final Color letterFlash;
}
