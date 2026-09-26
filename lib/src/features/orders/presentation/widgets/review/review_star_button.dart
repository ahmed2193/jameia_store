import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/product_review_request.dart';
import 'review_star_icon.dart';

/// One 44 dp star target, labelled "Rate n of 5".
class ReviewStarButton extends StatelessWidget {
  const ReviewStarButton({
    super.key,
    required this.star,
    required this.filled,
    required this.delaySteps,
    required this.enabled,
    required this.onTap,
  });

  /// One style for every star (5 per tile, rebuilt on each tap).
  static final ButtonStyle _style = IconButton.styleFrom(
    fixedSize: const Size.square(AppSize.s44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  final int star;
  final bool filled;

  /// Place of this star in a multi-star fill (see [ReviewStarIcon]).
  final int delaySteps;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'orders.review_star_label'.tr(
        namedArgs: {
          'count': '$star',
          'max': '${ProductReviewRequest.maxRating}',
        },
      ),
      onPressed: enabled ? onTap : null,
      style: _style,
      icon: ReviewStarIcon(filled: filled, delaySteps: delaySteps),
    );
  }
}
