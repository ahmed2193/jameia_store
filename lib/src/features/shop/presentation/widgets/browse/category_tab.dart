import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One top-level category in the store's tab bar: bold with the near-black
/// indicator while it is the open one. The indicator keeps its place when the
/// tab is idle (it is drawn in the bar's own colour), so nothing shifts.
class CategoryTab extends StatelessWidget {
  const CategoryTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _indicator = AppSize.s3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: AlignmentDirectional.center,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.tabIndicator : AppColors.white,
              width: _indicator,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingMedium.copyWith(
            fontSize: AppSize.font15,
            color: selected ? AppColors.primaryText : AppColors.secondaryText,
            fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
          ),
        ),
      ),
    );
  }
}
