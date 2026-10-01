import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/motion/pop_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../../../../core/widgets/hero_sheet_handle.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';

/// "Hide the assistant for today?" — pops `true` to hide, `false` to keep.
/// The sheet handle, the mascot (it settles in), then the words and the two
/// pills rising in one after the other — the confirmation dialog's look.
/// It scrolls when a small screen or large text leaves it too little room.
class AssistantBuddyHideSheet extends StatelessWidget {
  const AssistantBuddyHideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeroSheetHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s24,
                AppSpacing.s16,
                AppSpacing.s24,
                AppSpacing.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PopScale.onMount(
                    from: PopScale.artFrom,
                    child: AssistantMascot(
                      size: AppSize.s72,
                      mood: AssistantMascotMood.curious,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  EntranceCascadeItem.single(
                    index: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'assistant.buddy_hide_title'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.groupTitle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'assistant.buddy_hide_body'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.itemTitle.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  EntranceCascadeItem.single(
                    index: 2,
                    child: AppButton(
                      label: 'assistant.buddy_hide'.tr(),
                      onPressed: () => context.pop(true),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  EntranceCascadeItem.single(
                    index: 3,
                    child: HeroSecondaryButton(
                      label: 'assistant.buddy_keep'.tr(),
                      expanded: true,
                      onPressed: () => context.pop(false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
