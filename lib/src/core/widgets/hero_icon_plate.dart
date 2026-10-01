import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_icon_fill_colors.dart';
import '../design/hero_icons.dart';
import '../responsive/app_size.dart';
import 'hero_icon.dart';

/// A white Hero glyph centred on a rounded coloured tile — the plate style of
/// `offer_delivery.svg` / `pro_crown.svg`, for feature tiles, payment and offer
/// rows. The tile takes the icon's natural fill family ([plateColorOf]) unless
/// [color] is given; no accent layer is drawn on a plate.
class HeroIconPlate extends StatelessWidget {
  const HeroIconPlate(
    this.icon, {
    super.key,
    this.size = AppSize.s40,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;

  /// The tile's side.
  final double size;

  /// The tile colour; defaults to [plateColorOf] [icon]. Keep white on it at
  /// 3:1 or more.
  final Color? color;
  final String? semanticLabel;

  /// Corner radius and glyph size as a share of [size].
  static const double _cornerRatio = 0.28;
  static const double _glyphRatio = 0.6;

  /// The tile colour for [icon]: the crown keeps the Pro indigo of
  /// `pro_crown.svg`; any other icon its fill's plate colour, brand green
  /// for an icon without a fill (arrows, controls).
  static Color plateColorOf(IconData icon) => icon == HeroIcons.crown
      ? AppColors.proIndigo
      : HeroIcons.fillOf(icon)?.plate ?? AppColors.primaryDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? plateColorOf(icon),
          borderRadius: BorderRadius.all(Radius.circular(size * _cornerRatio)),
        ),
        child: Center(
          child: HeroIcon(
            icon,
            size: size * _glyphRatio,
            color: AppColors.white,
            semanticLabel: semanticLabel,
            mono: true,
          ),
        ),
      ),
    );
  }
}
