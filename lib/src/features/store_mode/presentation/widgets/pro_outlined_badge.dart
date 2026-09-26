import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';

/// Small white-outlined "Pro" chip on the violet account strip.
class ProOutlinedBadge extends StatelessWidget {
  const ProOutlinedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.white, width: AppSize.s1_5),
      ),
      child: Text(
        'pro.badge'.tr(),
        maxLines: 1,
        style: AppTextStyles.subheadingSmall.copyWith(
          color: AppColors.white,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
