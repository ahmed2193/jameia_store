import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// The small violet "pro" tag in front of the store name: the store runs the
/// Pro membership programme.
class HomeProBadge extends StatelessWidget {
  const HomeProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Pops in when the store's settings land.
    return PopScale.onMount(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s5,
          vertical: AppSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentViolet,
          borderRadius: BorderRadius.circular(AppSize.r4),
        ),
        child: Text(
          'home.pro_badge'.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.white,
            fontWeight: AppTextStyles.bold,
            height: AppSize.lh1_2,
          ),
        ),
      ),
    );
  }
}
