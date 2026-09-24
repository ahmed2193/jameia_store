import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/product_review_request.dart';

/// Five tappable stars; [rating] is 0 (not rated yet) to 5.
class ReviewStarBar extends StatelessWidget {
  const ReviewStarBar({
    super.key,
    required this.rating,
    required this.onRate,
    this.enabled = true,
  });

  final int rating;
  final ValueChanged<int> onRate;

  /// A review already sent (or one in flight) cannot be re-rated.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (
          var star = ProductReviewRequest.minRating;
          star <= ProductReviewRequest.maxRating;
          star++
        )
          IconButton(
            key: ValueKey<int>(star),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(AppSize.s4),
            onPressed: !enabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onRate(star);
                  },
            icon: Icon(
              star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: AppSize.s28,
              color: star <= rating
                  ? AppColors.primary
                  : AppColors.tertiaryText,
            ),
          ),
      ],
    );
  }
}
