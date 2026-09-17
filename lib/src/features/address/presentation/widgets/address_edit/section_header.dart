import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Section header — bold title with an optional required (*) marker.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.required = false});
  final String title;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.s12,
        end: AppSpacing.s12,
        top: AppSpacing.s14,
        bottom: AppSpacing.s10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          if (required)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.s2),
              child: Text(
                '*',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
