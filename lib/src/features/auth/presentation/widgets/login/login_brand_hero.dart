import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Brand-yellow top hero with the Jameia logo + wordmark.
class LoginBrandHero extends StatelessWidget {
  const LoginBrandHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.brandDarkBg],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s24),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r4),
            child: Image.asset(
              JameiaAssets.logo,
              width: AppSize.s64,
              height: AppSize.s64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            AppConstants.appName,
            style: AppTextStyles.displayLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.brandForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'auth.food_delivery_fast'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandForeground,
            ),
          ),
        ],
      ),
    );
  }
}
