import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// A glyph on a soft disc: what leads the address search's rows and the
/// address form's header.
class GlyphDisc extends StatelessWidget {
  const GlyphDisc({
    super.key,
    required this.icon,
    this.size = AppSize.s40,
    this.glyphSize = AppSize.s20,
    this.color = AppColors.brandWash,
  });

  final IconData icon;
  final double size;
  final double glyphSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: HeroIcon(icon, size: glyphSize),
    );
  }
}
