import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// One pill of the deepest category row: it fills with ink while it is the
/// open one (the fill and the label cross-fade), and sinks a touch under the
/// finger.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double height = AppSize.s36;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.fast);
    return PressScale(
      onTap: onTap,
      haptic: HapticKind.selection,
      child: AnimatedContainer(
        duration: duration,
        curve: MotionGuard.curve(context, AppMotion.signature),
        height: height,
        alignment: AlignmentDirectional.center,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryText : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryText : AppColors.divider,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: duration,
          style: AppTextStyles.bodyLarge.copyWith(
            color: selected ? AppColors.white : AppColors.primaryText,
            fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
