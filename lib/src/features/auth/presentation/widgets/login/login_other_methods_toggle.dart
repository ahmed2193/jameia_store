import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// "Other methods ⌄" under the Google pill: opens and closes the rest of
/// the ways in; the brand-green chevron turns over with it.
class LoginOtherMethodsToggle extends StatelessWidget {
  const LoginOtherMethodsToggle({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  static const double _halfTurn = 0.5;

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: expanded,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          minimumSize: const Size(0, AppSize.s48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'auth.other_methods'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            AnimatedRotation(
              turns: expanded ? _halfTurn : 0,
              duration: MotionGuard.duration(context, AppMotion.medium),
              curve: MotionGuard.curve(context, AppMotion.signature),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSize.s26,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
