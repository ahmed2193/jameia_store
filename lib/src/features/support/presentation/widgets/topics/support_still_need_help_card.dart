import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// "Still need help?" — the footer card under the topics, into the chat.
class SupportStillNeedHelpCard extends StatelessWidget {
  const SupportStillNeedHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        children: [
          Container(
            width: AppSize.s48,
            height: AppSize.s48,
            decoration: const BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              HeroIcons.customerService,
              size: AppSize.s24,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'support.still_need_help'.tr(),
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'support.still_need_help_body'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'support.contact_support'.tr(),
            radius: AppRadius.r2,
            trailing: const Icon(
              HeroIcons.chat,
              size: AppSize.s18,
              color: AppColors.brandForeground,
            ),
            onPressed: () => context.push(Routes.imChat),
          ),
        ],
      ),
    );
  }
}
