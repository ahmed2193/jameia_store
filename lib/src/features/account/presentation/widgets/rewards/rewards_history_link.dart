import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Soft cream "Points history" pill next to how redeeming works.
class RewardsHistoryLink extends StatelessWidget {
  const RewardsHistoryLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: PressScale(
        onTap: () => context.push(Routes.loyalty),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accent3Light,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s10,
              AppSpacing.s6,
              AppSpacing.s12,
              AppSpacing.s6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeroIcon(
                  HeroIcons.history,
                  size: AppSize.s16,
                  color: AppColors.voucherBrown,
                ),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  'loyalty.history'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.voucherBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
