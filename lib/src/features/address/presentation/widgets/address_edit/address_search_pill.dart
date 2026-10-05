import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_map_button.dart';

/// The search pill over the map picker, Glovo style — a soft grey pill
/// with the lens and a dark "Search address": a tap opens the place search
/// (the map stays as it is underneath).
class AddressSearchPill extends StatelessWidget {
  const AddressSearchPill({super.key, required this.onTap});

  final VoidCallback onTap;

  /// As tall as the map buttons beside it.
  static const double height = HeroMapButton.diameter;

  @override
  Widget build(BuildContext context) {
    final hint = 'addr.map.search_pill'.tr();
    return Semantics(
      button: true,
      label: hint,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        pressedScale: AppMotion.pressedScale,
        child: Container(
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            color: AppColors.smallBackground,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.low,
          ),
          child: Row(
            children: [
              const HeroIcon(
                HeroIcons.search,
                size: AppSize.s20,
                color: AppColors.primaryText,
                mono: true,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subheadingLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
