import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/jameia_secondary_button.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';

/// "Hide the assistant for today?" — pops `true` to hide, `false` to keep.
class AssistantBuddyHideSheet extends StatelessWidget {
  const AssistantBuddyHideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s20,
          AppSpacing.s24,
          AppSpacing.s20,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AssistantMascot(
              size: AppSize.s72,
              mood: AssistantMascotMood.curious,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'assistant.buddy_hide_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              'assistant.buddy_hide_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
                height: AppSize.lh1_5,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            AppButton(
              label: 'assistant.buddy_hide'.tr(),
              onPressed: () => context.pop(true),
            ),
            const SizedBox(height: AppSpacing.s8),
            JameiaSecondaryButton(
              label: 'assistant.buddy_keep'.tr(),
              expanded: true,
              onPressed: () => context.pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
