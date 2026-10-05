import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/building_type.dart';
import 'building_type_labels.dart';

/// One choice of the building-type sheet, Glovo style: the type's sticker
/// glyph over its name in a white tile with a hairline outline — mint with
/// a green ring once [selected].
class BuildingTypeTile extends StatelessWidget {
  const BuildingTypeTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final BuildingType type;
  final bool selected;
  final VoidCallback onTap;

  static const double _height = AppSize.s96;
  static const double _glyph = AppSize.s28;
  static const double _hairline = AppSize.s1;
  static const double _ring = AppSize.s1_5;

  @override
  Widget build(BuildContext context) {
    final name = buildingTypeName(type);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          height: _height,
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandWash : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.r5),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? _ring : _hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HeroIcon(buildingTypeIcon(type), size: _glyph),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.itemTitleStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
