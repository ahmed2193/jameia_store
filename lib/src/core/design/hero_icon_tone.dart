import 'dart:ui' show Color;

import '../../config/theme/app_colors.dart';

/// The colour pair a two-tone Hero icon (`HeroIcon(icon, tone: …)`) is drawn
/// in: the [line] glyph over its [accent] layer, instead of the sticker ink +
/// natural fill. Every pair comes from [AppColors], so icons take the app's
/// system colours (tool/icons SPEC "Colour").
enum HeroIconTone {
  /// Brand green surfaces.
  brand(AppColors.brandDeep, AppColors.brandLightBg),

  /// Hero Pro.
  pro(AppColors.proIndigo, AppColors.accentVioletLight),

  /// Offers, deals, discounts.
  offer(AppColors.accent1Dark, AppColors.accent1Light),

  /// Points, wallet, rewards: ink line over an amber fill.
  gold(AppColors.primaryText, AppColors.proAmber),

  /// Information, help.
  info(AppColors.link, AppColors.accentSkyLight),

  /// Warm, friendly moments.
  warm(AppColors.accent3Dark, AppColors.accent4Light),

  /// Quiet rows: ink line over the soft grey fill.
  neutral(AppColors.primaryText, AppColors.smallBackground);

  const HeroIconTone(this.line, this.accent);

  /// The line glyph's colour.
  final Color line;

  /// The accent layer's colour, under the line glyph.
  final Color accent;
}
