import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// A pill of the listing toolbar: the sort button (with a dropdown caret) or
/// an on / off filter.
class ListingFilterPill extends StatelessWidget {
  const ListingFilterPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.isDropdown = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;
  final bool isDropdown;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primaryDark : AppColors.primaryText;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppSize.s32,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLightBg : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSize.s16, color: foreground),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: AppTextStyles.captionLarge.copyWith(
                color: foreground,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.medium,
              ),
            ),
            if (isDropdown) ...[
              const SizedBox(width: AppSpacing.s2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSize.s16,
                color: foreground,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
