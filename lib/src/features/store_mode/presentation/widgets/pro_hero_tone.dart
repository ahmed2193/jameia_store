import 'package:flutter/painting.dart';

import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/pro_membership.dart';

/// Colour set of the paywall's hero band, picked by the billing interval of
/// the plan on show: the yearly plan gets the bold Pro gradient with lime
/// accents and an amber glow, every other plan the light lavender band with
/// Hero green and a violet glow. Both bands have three stops, so switching
/// plans tweens one into the other.
enum ProHeroTone {
  bold(
    band: AppColors.proGradient,
    lineOne: AppColors.white,
    lineTwo: AppColors.proLime,
    stroke: AppColors.proLime,
    archFill: AppColors.accentVioletLight,
    glow: AppColors.proAmber,
  ),
  light(
    band: [
      AppColors.accentVioletLight,
      AppColors.accentVioletLight,
      AppColors.accentSkyLight,
    ],
    lineOne: AppColors.primaryText,
    lineTwo: AppColors.accentViolet,
    stroke: AppColors.primary,
    archFill: AppColors.white,
    glow: AppColors.accentViolet,
  );

  const ProHeroTone({
    required this.band,
    required this.lineOne,
    required this.lineTwo,
    required this.stroke,
    required this.archFill,
    required this.glow,
  });

  /// Band background stops, top-start → bottom-end.
  final List<Color> band;

  /// First headline line.
  final Color lineOne;

  /// Second (accent) headline line.
  final Color lineTwo;

  /// Arch outline and the spark doodle.
  final Color stroke;

  /// Inside of the arch, behind the Hero bag.
  final Color archFill;

  /// Soft breathing light behind the bag.
  final Color glow;

  /// The band as a 135° gradient (mirrored in RTL).
  LinearGradient get bandGradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: band,
  );

  static ProHeroTone of(ProBillingInterval interval) =>
      interval == ProBillingInterval.year ? bold : light;
}
