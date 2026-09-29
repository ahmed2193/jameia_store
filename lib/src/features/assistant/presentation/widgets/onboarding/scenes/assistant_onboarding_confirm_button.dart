import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/motion/motion_widgets.dart';
import '../../../../../../core/responsive/app_size.dart';

/// The cart demo's "Confirm": green until tapped (by the customer, or by
/// the ghost finger — [pressed] while it pushes), then "Added to cart" on a
/// soft green with a check.
class AssistantOnboardingConfirmButton extends StatelessWidget {
  const AssistantOnboardingConfirmButton({
    super.key,
    required this.confirmed,
    required this.pressed,
    required this.onTap,
  });

  final bool confirmed;
  final bool pressed;
  final VoidCallback onTap;

  static const double _height = AppSize.s36;

  @override
  Widget build(BuildContext context) {
    final foreground = confirmed ? AppColors.primaryDark : AppColors.white;
    return AnimatedScale(
      scale: pressed ? AppMotion.pressedScale : 1,
      duration: MotionGuard.duration(
        context,
        pressed ? AppMotion.microPop : AppMotion.fast,
      ),
      curve: AppMotion.signature,
      child: PressScale(
        onTap: confirmed ? null : onTap,
        enabled: !confirmed,
        child: AnimatedContainer(
          height: _height,
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: AppMotion.signature,
          decoration: BoxDecoration(
            color: confirmed ? AppColors.brandLightBg : AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: PopSwitcher(
              stateKey: confirmed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    confirmed
                        ? Icons.check_circle_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: AppSize.s16,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.s6),
                  Text(
                    (confirmed
                            ? 'assistant.onboarding_demo_added'
                            : 'assistant.onboarding_demo_confirm')
                        .tr(),
                    style: AppTextStyles.subheadingMedium.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
