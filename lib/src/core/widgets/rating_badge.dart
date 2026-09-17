import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// Small rating pill: ★ 4.8 in Jameia's bold digit style.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.count,
    this.size = 12,
  });

  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.warn),
        const SizedBox(width: AppSpacing.s2),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.captionLarge.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.primaryText,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.s2),
          Text(
            '($count)',
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ],
      ],
    );
  }
}
