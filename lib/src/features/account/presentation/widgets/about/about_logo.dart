import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/responsive/app_size.dart';

/// The JameiaMart app icon on a rounded, softly lifted tile.
class AboutLogo extends StatelessWidget {
  const AboutLogo({super.key});

  static const double size = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(AppRadius.r2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: corners,
        boxShadow: AppShadows.high,
      ),
      child: ClipRRect(
        borderRadius: corners,
        child: Image.asset(
          JameiaAssets.appLogo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // The source is 1024 px; decode only what the tile shows.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
