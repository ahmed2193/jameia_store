import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../chat/assistant_avatar.dart';
import 'assistant_onboarding_skeleton_bar.dart';

/// The greeting in miniature, as it drops into the ready demo's phone: the
/// assistant's face and two lines of text.
class AssistantOnboardingPhoneToast extends StatelessWidget {
  const AssistantOnboardingPhoneToast({super.key});

  static const double _line = AppSize.s4;
  static const double _firstShare = 0.9;
  static const double _secondShare = 0.6;
  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r5)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandLightBg)),
    boxShadow: AppShadows.medium,
  );

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: _card,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6),
        child: Row(
          children: [
            AssistantAvatar(size: AppSize.s18),
            SizedBox(width: AppSpacing.s6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssistantOnboardingSkeletonBar(
                    widthFactor: _firstShare,
                    height: _line,
                    color: AppColors.primaryText,
                  ),
                  SizedBox(height: AppSpacing.s4),
                  AssistantOnboardingSkeletonBar(
                    widthFactor: _secondShare,
                    height: _line,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
