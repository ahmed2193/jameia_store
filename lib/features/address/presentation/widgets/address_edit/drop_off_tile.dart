import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Drop-off option tile (hand-to-me vs leave-at-spot).
class DropOffTile extends StatelessWidget {
  const DropOffTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.fast),
        curve: MotionGuard.curve(context, AppMotion.standard),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLightBg : AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppRadius.r4),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primaryText : AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            PopScale(
              popKey: selected,
              child: Image.asset(
                selected
                    ? 'assets/images/keeta/order_confirm/drop_off_option_selected_1zm6gs.png'
                    : 'assets/images/keeta/order_confirm/drop_off_option_unselected_1m4vrwk.png',
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) => Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? AppColors.primaryText
                      : AppColors.disabledText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
