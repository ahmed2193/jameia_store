import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One pill of the deepest category row: filled while it is the open one.
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppSize.s32,
        alignment: AlignmentDirectional.center,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s14,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryText : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryText : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionLarge.copyWith(
            color: selected ? AppColors.white : AppColors.primaryText,
            fontWeight: selected ? AppTextStyles.bold : AppTextStyles.medium,
          ),
        ),
      ),
    );
  }
}
