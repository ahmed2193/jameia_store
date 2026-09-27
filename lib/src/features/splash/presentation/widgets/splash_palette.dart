import 'dart:ui';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_mark_painting.dart';

/// The colours of one splash scene: the white bag in its yellow cape on the
/// Hero green of the launch screen ([onBrand]), or the full-colour logo on
/// white ([onWhite], what the burst reveal turns the screen into).
class SplashPalette {
  const SplashPalette._({
    required this.background,
    required this.mark,
    required this.letter,
    required this.speedLine,
    required this.bottle,
    required this.bottleCap,
    required this.fruit,
    required this.fruitLeaf,
    required this.greens,
    required this.glow,
    required this.aurora,
    required this.ripple,
    required this.confetti,
    required this.shine,
  });

  /// White logo on the brand green — the native launch screen's colours.
  static const SplashPalette onBrand = SplashPalette._(
    background: AppColors.primary,
    mark: HeroMarkColors.onBrand,
    letter: AppColors.white,
    speedLine: AppColors.subtitleOverlay,
    bottle: AppColors.brandLightBg,
    bottleCap: AppColors.accent4,
    fruit: AppColors.accent3,
    fruitLeaf: AppColors.brandDeep,
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
  );

  /// The logo's own colours on white: green bag, amber cape, deep green name.
  static const SplashPalette onWhite = SplashPalette._(
    background: AppColors.white,
    mark: HeroMarkColors.onWhite,
    letter: AppColors.primaryDark,
    speedLine: AppColors.brandLightBg,
    bottle: AppColors.brandLightBg,
    bottleCap: AppColors.proAmber,
    fruit: AppColors.accent3,
    fruitLeaf: AppColors.primary,
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
      AppColors.proAmber,
      AppColors.brandDeep,
    ],
    shine: AppColors.white,
  );

  final Color background;

  /// The bag, its cape and the cape's underside.
  final HeroMarkColors mark;

  /// The delivered name (and the tagline under it).
  final Color letter;
  final Color speedLine;

  /// The groceries of the basket scene.
  final Color bottle;
  final Color bottleCap;
  final Color fruit;
  final Color fruitLeaf;
  final Color greens;

  /// Soft light behind the logo.
  final Color glow;

  /// Colours of the slow blobs drifting in the background.
  final List<Color> aurora;

  /// Take-off, arrival and tap rings.
  final Color ripple;

  /// Pieces of the celebration burst.
  final List<Color> confetti;

  /// The light that sweeps the finished lockup.
  final Color shine;
}
