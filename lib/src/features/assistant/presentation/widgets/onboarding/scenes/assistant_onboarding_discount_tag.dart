import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';

/// The deal's "−20%" in the promotion yellow, popping in with [appear].
class AssistantOnboardingDiscountTag extends StatelessWidget {
  const AssistantOnboardingDiscountTag({super.key, required this.appear});

  final double appear;

  static const BoxDecoration _tag = BoxDecoration(
    color: AppColors.promotionTagBg,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r6)),
  );

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: appear,
      child: DecoratedBox(
        decoration: _tag,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s2,
          ),
          child: Text(
            'assistant.onboarding_demo_discount'.tr(),
            style: AppTextStyles.tag.copyWith(color: AppColors.promotionTagFg),
          ),
        ),
      ),
    );
  }
}
