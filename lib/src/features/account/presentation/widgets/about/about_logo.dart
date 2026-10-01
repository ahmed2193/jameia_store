import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_app_logo.dart';

/// The Hero app icon on a rounded, softly lifted tile.
class AboutLogo extends StatelessWidget {
  const AboutLogo({super.key});

  static const double size = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r2),
        boxShadow: AppShadows.high,
      ),
      child: const HeroAppLogo(size: size, radius: AppRadius.r2),
    );
  }
}
