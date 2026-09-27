import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/light_sweep.dart';

/// "Take a quick tour" — the first greeting's leading chip: filled brand
/// green with a sparkle and a slow sheen, so it reads as the way in.
class AssistantBuddyTourChip extends StatelessWidget {
  const AssistantBuddyTourChip({super.key, required this.onTap});

  final VoidCallback onTap;

  static const BorderRadius _pill = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SuiSize.minTouchTarget),
          child: LightSweep(
            borderRadius: _pill,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: _pill,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s14,
                  vertical: AppSpacing.s8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: AppSize.s16,
                      color: AppColors.brandForeground,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Flexible(
                      child: Text(
                        'assistant.onboarding_take_tour'.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subheadingMedium.copyWith(
                          color: AppColors.brandForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
