import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// One perk of the Pro banner ("Free delivery", "×2 points"). [active]: a
/// member's perk, led by a check — it is already switched on.
class HomeProPerkChip extends StatelessWidget {
  const HomeProPerkChip({super.key, required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.popupCloseScrim,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            const HeroIcon(
              HeroIcons.checkCircleFill,
              size: AppSize.s14,
              color: AppColors.proLime,
            ),
            const SizedBox(width: AppSpacing.s4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.white,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
