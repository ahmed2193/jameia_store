import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import 'mine_tone.dart';

/// A glyph on a soft tinted tile ([tone]): a rounded square in the menu
/// rows, a disc on the quick-stat tiles ([circle]).
///
/// The glyph is an [icon], or a drawn `HeroAssets` SVG ([asset]): a mono
/// line icon is tinted like the icon; a colour [plate] (wallet, points,
/// ticket, gift, Pro crown) brings its own tile and fills the slot instead.
class MineIconTile extends StatelessWidget {
  const MineIconTile({
    super.key,
    this.icon,
    this.asset,
    this.plate = false,
    required this.tone,
    this.circle = false,
  }) : assert((icon == null) != (asset == null), 'an icon or an asset');

  static const double size = AppSize.s32;
  static const double _glyph = AppSize.s18;

  final IconData? icon;
  final String? asset;
  final bool plate;
  final MineTone tone;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final drawn = asset;
    if (drawn != null && plate) {
      return HeroSvgGlyph.art(drawn, size: size);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppRadius.r5),
      ),
      child: drawn == null
          ? Icon(icon, size: _glyph, color: tone.foreground)
          : HeroSvgGlyph.mono(drawn, size: _glyph, color: tone.foreground),
    );
  }
}
