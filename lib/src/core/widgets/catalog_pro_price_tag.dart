import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// The Pro price of a product as a small tag, for customers who are not Pro
/// members yet (`proPrice` on the backend row). Members see that price as the
/// price itself, so they never get this tag.
class CatalogProPriceTag extends StatelessWidget {
  const CatalogProPriceTag({super.key, required this.priceKd});

  final double priceKd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent4Light,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        'catalog.pro_price'.tr(namedArgs: {'price': Formatters.price(priceKd)}),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.accent4Foreground,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
