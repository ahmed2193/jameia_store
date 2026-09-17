import 'package:flutter/material.dart';

import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/radio_dot.dart';

/// One candidate row: a radio circle + title + subtitle.
class CandidateRow extends StatelessWidget {
  const CandidateRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: selected ? AppColors.brandLightBg : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioDot(selected: selected),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
