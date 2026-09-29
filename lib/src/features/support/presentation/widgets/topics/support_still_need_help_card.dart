import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// "Still need help?" — the footer card under the topics, into the chat,
/// headed by the Hero teammate drawing ([HeroAssets.assistantPropHandoff],
/// decorative; mirrored in RTL like everywhere it appears).
class SupportStillNeedHelpCard extends StatelessWidget {
  const SupportStillNeedHelpCard({super.key});

  static const double _art = AppSize.s72;

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
          SvgPicture.asset(
            HeroAssets.assistantPropHandoff,
            width: _art,
            height: _art,
            matchTextDirection: true,
            excludeFromSemantics: true,
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
