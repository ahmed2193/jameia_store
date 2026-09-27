import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../domain/entities/catalog_merch_tag.dart';
import '../domain/entities/catalog_product_entity.dart';
import '../responsive/app_size.dart';

/// The one merchandising tag a listing card wears above its name — "Best
/// seller" or "Fresh" — from the product's backend tags. Keeps its line when
/// the product has none, so every card in a row lines up. The line grows
/// with the reader's text scale, so the pill's text is never clipped.
class ShelfTagPill extends StatelessWidget {
  const ShelfTagPill({super.key, required this.product});

  final CatalogProductEntity product;

  /// The line the pill takes at the default text scale (also reserved
  /// without one); it scales with the reader's text.
  static const double height = AppSize.s22;

  /// Whether [product] has a tag the pill shows — a page that need not line
  /// cards up skips the pill's empty line without one.
  static bool wears(CatalogProductEntity product) =>
      product.leadMerchTag != null;

  @override
  Widget build(BuildContext context) {
    final line = MediaQuery.textScalerOf(context).scale(height);
    // The most telling tag only.
    final tag = product.leadMerchTag;
    if (tag == null) return SizedBox(height: line);
    final (ink, plate) = switch (tag) {
      CatalogMerchTag.bestSeller => (
        AppColors.accent1Dark,
        AppColors.accent1Light,
      ),
      CatalogMerchTag.fresh => (
        AppColors.martGreenDark,
        AppColors.martGreenLight,
      ),
    };
    return SizedBox(
      height: line,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: plate,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r6)),
          ),
          child: Text(
            tag.labelKey.tr(),
            maxLines: 1,
            style: AppTextStyles.bodyMedium.copyWith(color: ink),
          ),
        ),
      ),
    );
  }
}
