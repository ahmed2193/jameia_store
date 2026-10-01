import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_image.dart';

/// One sub-category of the folded rail: a pill with the artwork in a small
/// circle before the name, filled in ink while it is the open one. The rail
/// folds into these while the listing scrolls (see `CategoryRailHeader`).
class CategoryRailChip extends StatelessWidget {
  const CategoryRailChip({
    super.key,
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
    this.all = false,
  });

  final String label;

  /// Empty for a category the backend has no artwork for: a neutral glyph.
  final String image;
  final bool selected;
  final VoidCallback onTap;

  /// The "All" chip: the Hero category-all glyph
  /// ([HeroIcons.categoryAll]) instead of an [image].
  final bool all;

  static const double height = AppSize.s36;
  static const double _image = AppSize.s28;
  static const double _glyph = AppSize.s18;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      haptic: HapticKind.selection,
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.fast),
        curve: MotionGuard.curve(context, AppMotion.signature),
        height: height,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s4,
          AppSpacing.s4,
          AppSpacing.s12,
          AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryText : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryText : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: ColoredBox(
                color: AppColors.white,
                child: SizedBox.square(
                  dimension: _image,
                  child: all
                      ? const HeroIcon(
                          HeroIcons.categoryAll,
                          size: _glyph,
                          color: AppColors.primaryText,
                        )
                      : image.isEmpty
                      ? const HeroIcon(
                          HeroIcons.category,
                          size: _glyph,
                          color: AppColors.secondaryText,
                        )
                      : HeroImage.circle(url: image, size: _image),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge.copyWith(
                color: selected ? AppColors.white : AppColors.primaryText,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
