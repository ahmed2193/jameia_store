import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/motion/motion_widgets.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../../../../../core/widgets/branded_dot_loader.dart';
import '../../chat/assistant_avatar.dart';

/// The assistant's answer in the ask demo: its little face and a white
/// bubble that thinks (dots) until [answered], then pops the answer in.
class AssistantOnboardingReplyBubble extends StatelessWidget {
  const AssistantOnboardingReplyBubble({
    super.key,
    required this.appear,
    required this.answered,
  });

  /// The bubble's scale as it pops in from its tail.
  final double appear;
  final bool answered;

  static const double _dots = AppSize.s24;
  static const BoxDecoration _bubble = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadiusDirectional.only(
      topStart: Radius.circular(SuiRadius.bubble),
      topEnd: Radius.circular(SuiRadius.bubble),
      bottomStart: Radius.circular(AppSize.r4),
      bottomEnd: Radius.circular(SuiRadius.bubble),
    ),
    boxShadow: AppShadows.low,
  );

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: appear,
      alignment: AlignmentDirectional.bottomStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AssistantAvatar(size: AppSize.s22),
          const SizedBox(width: AppSpacing.s6),
          DecoratedBox(
            decoration: _bubble,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              child: PopSwitcher(
                stateKey: answered,
                alignment: AlignmentDirectional.centerStart,
                child: answered
                    ? Text(
                        'assistant.onboarding_demo_answer'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryText,
                        ),
                      )
                    : const BrandedDotLoader(
                        size: _dots,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
