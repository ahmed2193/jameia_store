import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/responsive/app_size.dart';

/// The store badge the home header opens with: the Hero app icon on a
/// rounded, hairline-framed tile.
class HomeStoreLogo extends StatelessWidget {
  const HomeStoreLogo({super.key});

  static const double size = AppSize.s48;

  static final BorderRadius _corners = BorderRadius.circular(AppSize.r12);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: _corners),
      // Over the artwork, so the frame is not hidden under it.
      foregroundDecoration: BoxDecoration(
        borderRadius: _corners,
        border: Border.all(color: AppColors.divider),
      ),
      child: Image.asset(
        HeroAssets.appLogo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // The source is 1024 px; decode only what the tile shows.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        excludeFromSemantics: true,
      ),
    );
  }
}
