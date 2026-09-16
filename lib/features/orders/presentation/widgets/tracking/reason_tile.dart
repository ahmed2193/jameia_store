import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ReasonTile extends StatelessWidget {
  const ReasonTile({
    super.key,
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final String reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Expanded(child: Text(reason.tr(), style: AppTextStyles.bodyLarge)),
            AnimatedContainer(
              duration: MotionGuard.duration(context, AppMotion.fast),
              curve: AppMotion.standard,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
