import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../assistant_word_reveal.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_buddy_close_button.dart';

/// The greeting's top row: the mascot on its disc, who is speaking,
/// [greeting] and the [message] revealing word by word — then "not now".
/// The mascot holds its talking pose while the message reveals, eases to a
/// smile once ([mood]) and stays still (docs/motion §9.6 §3.3).
class AssistantBuddyGreetingHeader extends StatelessWidget {
  const AssistantBuddyGreetingHeader({
    super.key,
    required this.greeting,
    required this.message,
    required this.mood,
    required this.onTyped,
    required this.onClose,
  });

  final String greeting;
  final String message;
  final AssistantMascotMood mood;
  final VoidCallback onTyped;
  final VoidCallback onClose;

  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: AppSize.s56,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AssistantMascot(size: AppSize.s52, mood: mood),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'assistant.title'.tr(),
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.brandDeep,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.s4),
              AssistantWordReveal(
                text: message,
                maxLines: _maxLines,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
                onDone: onTyped,
              ),
            ],
          ),
        ),
        AssistantBuddyCloseButton(onTap: onClose),
      ],
    );
  }
}
