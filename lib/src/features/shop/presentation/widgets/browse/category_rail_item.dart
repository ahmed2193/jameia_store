import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_image.dart';

/// One circle of the sub-category rail: the artwork, the name below it. The
/// open one wears an ink ring and a bold name and grows a touch while the
/// others settle back, so the eye lands on it. Also draws the "All" entry
/// (the artwork of the category the rail belongs to).
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
  static const double _image = AppSize.s54;
  static const double _labelWidth = AppSize.s76;
  static const double _ringWidth = AppSize.s2;
  static const double _pressedScale = 0.97;

  /// The resting size of an entry that is not the open one.
  static const double _restingScale = 0.92;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.medium);
    return PressScale(
      onTap: onTap,
      pressedScale: _pressedScale,
      haptic: HapticKind.selection,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1 : _restingScale,
            duration: duration,
            curve: AppMotion.emphasized,
            child: AnimatedContainer(
              duration: duration,
              curve: MotionGuard.curve(context, AppMotion.standard),
              width: _ring,
              height: _ring,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // The ring is always there, clear until picked, so nothing
                // shifts when it turns ink.
                border: Border.all(
                  color: selected ? AppColors.primaryText : AppColors.white,
                  width: _ringWidth,
                ),
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: AppColors.smallBackground,
                  child: SizedBox.square(
                    dimension: _image,
                    child: image.isEmpty
                        ? const Icon(
                            Icons.category_outlined,
                            size: AppSize.s24,
                            color: AppColors.secondaryText,
                          )
                        : HeroImage.circle(url: image, size: _image),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: _labelWidth,
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: AppTextStyles.captionLarge.copyWith(
                height: AppSize.lh1_2,
                color: selected
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.regular,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
