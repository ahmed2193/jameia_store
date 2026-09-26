import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import 'pdp_rating_stars.dart';

/// The head of the reviews: the average in big ink digits, its stars and
/// how many reviews it is based on.
class PdpReviewsSummary extends StatelessWidget {
  const PdpReviewsSummary({
    super.key,
    required this.average,
    required this.count,
  });

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          Formatters.rating(average),
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.primaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PdpRatingStars(rating: average.round()),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'product.based_on_reviews'.tr(namedArgs: {'count': '$count'}),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
