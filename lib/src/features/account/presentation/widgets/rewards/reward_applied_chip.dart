import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Green "✓ Applied" pill beside the points of the tier that is on the
/// basket right now.
class RewardAppliedChip extends StatelessWidget {
  const RewardAppliedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent2Light,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s8,
          AppSpacing.s2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: AppSize.s14,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              'loyalty.reward_applied_chip'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppTextStyles.bold,
                color: AppColors.accent2Dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
