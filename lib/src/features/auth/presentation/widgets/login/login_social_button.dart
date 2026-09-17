import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Outlined social sign-in button with a leading brand icon.
class LoginSocialButton extends StatelessWidget {
  const LoginSocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Passive press-scale (no onTap) so the InkWell keeps owning the gesture +
    // ripple while the whole button still gives Jameia's subtle press feel.
    return PressScale(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          onTap: onTap,
          child: Container(
            height: AppSize.s50,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r4),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Image.asset(
                  icon,
                  width: AppSize.s22,
                  height: AppSize.s22,
                  fit: BoxFit.contain,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSize.s22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
