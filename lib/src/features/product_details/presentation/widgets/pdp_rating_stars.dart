import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/app_size.dart';

/// Five stars, [rating] of them filled.
class PdpRatingStars extends StatelessWidget {
  const PdpRatingStars({super.key, required this.rating});

  final int rating;

  static const int _max = 5;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= _max; star++)
          Icon(
            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: AppSize.s16,
            color: star <= rating ? AppColors.warn : AppColors.disabledText,
          ),
      ],
    );
  }
}
