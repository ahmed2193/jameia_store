import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// Washes out the image of a product that is out of stock.
class CatalogUnavailableOverlay extends StatelessWidget {
  const CatalogUnavailableOverlay({super.key});

  static const double _wash = 0.6;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: _wash),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Center(
        child: Text(
          'catalog.out_of_stock'.tr(),
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.secondaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
    );
  }
}
