import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_icon_plate.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import 'mine_tone.dart';

/// A menu row's mark: the [icon] white on a [HeroIconPlate] in the
/// [MineTone.plate] colour, beside the art plates of the other rows; on the
/// quick-stat tiles ([circle]) the sticker [icon] on a soft
/// [MineTone.background] disc.
///
/// A colour [plate] (`HeroAssets` path: wallet, points, ticket, gift, Pro
/// crown) brings its own tile and fills the slot instead.
class MineIconTile extends StatelessWidget {
  const MineIconTile({
    super.key,
    this.icon,
    this.plate,
    required this.tone,
    this.circle = false,
  }) : assert((icon == null) != (plate == null), 'an icon or a plate');

  static const double size = AppSize.s32;
  static const double _glyph = AppSize.s18;

  final IconData? icon;
  final String? plate;
  final MineTone tone;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    if (plate case final String art) {
      return HeroSvgGlyph.art(art, size: size);
    }
    if (!circle) {
      return HeroIconPlate(icon!, size: size, color: tone.plate);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
      child: HeroIcon(icon!, size: _glyph, color: AppColors.primaryText),
    );
  }
}
