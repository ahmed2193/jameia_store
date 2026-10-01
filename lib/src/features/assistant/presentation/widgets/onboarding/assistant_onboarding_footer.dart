import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The tour's buttons, one height on every step: "Skip" and "Next" on the
/// way, "Maybe later" and "Start chatting" on the last step — each pops
/// into the other's place.
class AssistantOnboardingFooter extends StatelessWidget {
  const AssistantOnboardingFooter({
    super.key,
    required this.last,
    required this.onNext,
    required this.onSkip,
    required this.onStart,
    required this.onLater,
  });

  final bool last;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onStart;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopSwitcher(
          stateKey: last,
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: last ? onLater : onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryText,
              minimumSize: const Size(0, SuiSize.minTouchTarget),
            ),
            child: Text(
              (last
                      ? 'assistant.onboarding_later'
                      : 'assistant.onboarding_skip')
                  .tr(),
              style: AppTextStyles.subheadingMedium,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: PopSwitcher(
            stateKey: last,
            child: AppButton(
              label:
                  (last
                          ? 'assistant.onboarding_start'
                          : 'assistant.onboarding_next')
                      .tr(),
              onPressed: last ? onStart : onNext,
              trailing: HeroIcon(
                last ? HeroIcons.chatFill : HeroIcons.arrowForward,
                size: AppSize.s18,
                color: AppColors.brandForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
