import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "24 products" above a plain listing's grid: the matches on the server,
/// across all pages.
class ListingResultsCount extends StatelessWidget {
  const ListingResultsCount({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.pageMargin,
      ),
      child: Text(
        'shop.results_count'.tr(namedArgs: {'count': '$total'}),
        style: AppTextStyles.captionLarge.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
