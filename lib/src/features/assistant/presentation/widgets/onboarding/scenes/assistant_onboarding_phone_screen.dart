import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/responsive/app_size.dart';
import 'assistant_onboarding_skeleton_bar.dart';

/// What the ready demo's little phone shows under the assistant: a sketch
/// of the app — a notch, a banner, product tiles, lines of text and the
/// bottom bar with Home lit.
class AssistantOnboardingPhoneScreen extends StatelessWidget {
  const AssistantOnboardingPhoneScreen({super.key});

  static const double _notchWidth = AppSize.s30;
  static const double _line = AppSize.s6;
  static const double _banner = AppSize.s34;
  static const double _tile = AppSize.s30;
  static const double _tab = AppSize.s6;
  static const int _tabs = 4;
  static const double _bannerShare = 1;
  static const double _titleShare = 0.6;
  static const double _lineShare = 0.85;
  static const double _shortShare = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s10,
        AppSpacing.s6,
        AppSpacing.s10,
        AppSpacing.s8,
      ),
      child: Column(
        children: [
          const SizedBox(
            width: _notchWidth,
            child: AssistantOnboardingSkeletonBar(
              widthFactor: 1,
              height: AppSize.s4,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          const AssistantOnboardingSkeletonBar(
            widthFactor: _bannerShare,
            height: _banner,
            color: AppColors.brandLightBg,
          ),
          const SizedBox(height: AppSpacing.s8),
          const AssistantOnboardingSkeletonBar(
            widthFactor: _titleShare,
            height: _line,
          ),
          const SizedBox(height: AppSpacing.s8),
          const Row(
            children: [
              Expanded(
                child: AssistantOnboardingSkeletonBar(
                  widthFactor: 1,
                  height: _tile,
                  color: AppColors.smallBackground,
                ),
              ),
              SizedBox(width: AppSpacing.s6),
              Expanded(
                child: AssistantOnboardingSkeletonBar(
                  widthFactor: 1,
                  height: _tile,
                  color: AppColors.smallBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          const AssistantOnboardingSkeletonBar(
            widthFactor: _lineShare,
            height: _line,
          ),
          const SizedBox(height: AppSpacing.s6),
          const AssistantOnboardingSkeletonBar(
            widthFactor: _shortShare,
            height: _line,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var tab = 0; tab < _tabs; tab++)
                SizedBox.square(
                  dimension: _tab,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tab == 0 ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
