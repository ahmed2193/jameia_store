import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/responsive/app_size.dart';

/// The delivery slot the "more" demo books — "Today 6–7 pm", checked on a
/// soft green — popping in with [appear].
class AssistantOnboardingSlotChip extends StatelessWidget {
  const AssistantOnboardingSlotChip({super.key, required this.appear});

  final double appear;

  static const BoxDecoration _chip = BoxDecoration(
    color: AppColors.brandLightBg,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.primary)),
  );

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: appear,
      child: DecoratedBox(
        decoration: _chip,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                size: AppSize.s12,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                'assistant.onboarding_demo_slot_today'.tr(),
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
