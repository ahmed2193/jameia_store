import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// The count pill on a bottom-nav icon. It pops when the count changes, so an
/// add from anywhere in the app is felt on the tab bar; 100 and up read `99+`.
class ShellNavBadge extends StatelessWidget {
  const ShellNavBadge({super.key, required this.count});

  final int count;

  static const int _cap = 99;

  @override
  Widget build(BuildContext context) {
    return PopScale(
      popKey: count,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s4,
        ),
        constraints: const BoxConstraints(
          minWidth: AppSize.s16,
          minHeight: AppSize.s16,
        ),
        decoration: BoxDecoration(
          color: AppColors.finalPrice,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.white, width: AppSize.s1),
        ),
        alignment: Alignment.center,
        child: Text(
          count > _cap ? '$_cap+' : '$count',
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.white,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
    );
  }
}
