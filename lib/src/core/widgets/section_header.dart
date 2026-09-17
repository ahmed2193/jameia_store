import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// Section header row: bold title + optional trailing "see all" arrow.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.pageMargin,
      AppSpacing.s16,
      AppSpacing.pageMargin,
      AppSpacing.s8,
    ),
  });

  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: AppSize.s20,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}
