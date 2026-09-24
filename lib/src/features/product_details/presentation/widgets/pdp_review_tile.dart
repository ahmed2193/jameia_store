import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/product_reviews.dart';
import 'pdp_rating_stars.dart';

/// One customer review: stars, who and when, title and text.
class PdpReviewTile extends StatelessWidget {
  const PdpReviewTile({super.key, required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd(context.locale.languageCode)
        .format(review.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PdpRatingStars(rating: review.rating),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  review.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ),
              Text(
                date,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ),
          if (review.title.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              review.title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ],
          if (review.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              review.body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
