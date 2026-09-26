import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';

/// "★ 4.5 · 12 reviews" in the grey line under the product's name; the
/// count is underlined and a tap anywhere on it scrolls to the reviews.
class PdpRatingSummary extends StatelessWidget {
  const PdpRatingSummary({
    super.key,
    required this.rating,
    required this.count,
    this.onTap,
  });

  final double rating;
  final int count;
  final VoidCallback? onTap;

  static const String _separator = '·';

  @override
  Widget build(BuildContext context) {
    final grey = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: AppSize.s16,
              color: AppColors.warn,
            ),
            const SizedBox(width: AppSpacing.s2),
            Text(
              Formatters.rating(rating),
              style: grey.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.medium,
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
            Text(_separator, style: grey),
            const SizedBox(width: AppSpacing.s6),
            Flexible(
              child: Text(
                'product.reviews_count'.tr(namedArgs: {'count': '$count'}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: grey.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
