import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';

/// The rider's disc: the caped Hero rider of the map on the green wash (the
/// feed sends no photo, so none is faked). Decorative.
class LiveMapRiderAvatar extends StatelessWidget {
  const LiveMapRiderAvatar({super.key});

  static const double _disc = AppSize.s44;
  static const double _art = AppSize.s34;

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox.square(
        dimension: _disc,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandLightBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: HeroSvgGlyph.art(HeroAssets.mapRider, size: _art),
          ),
        ),
      ),
    );
  }
}
