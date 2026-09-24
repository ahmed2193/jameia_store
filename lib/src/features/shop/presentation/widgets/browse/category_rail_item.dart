import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_image.dart';

/// One circle of the sub-category rail: the artwork in a ring that lights up
/// while it is the open sub-category, the name below it. Also draws the "All"
/// entry (the artwork of the category the rail belongs to).
class CategoryRailItem extends StatelessWidget {
  const CategoryRailItem({
    super.key,
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Empty for a category the backend has no artwork for: a neutral tile.
  final String image;
  final bool selected;
  final VoidCallback onTap;

  static const double _ring = AppSize.s64;
  static const double _image = AppSize.s56;
  static const double _labelWidth = AppSize.s76;
  static const double _selectedBorder = AppSize.s2;
  static const double _idleBorder = AppSize.s1;
  static const double _ringTint = 0.10;
  static const double _ringGlow = 0.30;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: MotionGuard.curve(context, AppMotion.standard),
            width: _ring,
            height: _ring,
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: _ringTint)
                  : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? _selectedBorder : _idleBorder,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: _ringGlow),
                        blurRadius: AppSize.r5,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: image.isEmpty
                ? const Icon(
                    Icons.category_outlined,
                    size: AppSize.s24,
                    color: AppColors.secondaryText,
                  )
                : JameiaImage.circle(url: image, size: _image),
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMedium.copyWith(
                fontSize: AppSize.font11,
                height: AppSize.lh1_2,
                color: selected
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
