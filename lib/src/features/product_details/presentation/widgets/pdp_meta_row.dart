import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import 'pdp_rating_summary.dart';

/// The grey line under the product's name: its unit of sale, what kind of
/// product it is ("Multiple sizes", "Bundle") and, when it has been rated,
/// the rating link to the reviews — set apart by middle dots, wrapping on a
/// narrow screen.
class PdpMetaRow extends StatelessWidget {
  const PdpMetaRow({super.key, required this.product, this.onOpenReviews});

  final CatalogProductEntity product;
  final VoidCallback? onOpenReviews;

  static const String _separator = '·';

  static String? _typeKey(CatalogProductEntity product) =>
      switch (product.type) {
        CatalogProductType.variant => 'catalog.multiple_sizes',
        CatalogProductType.bundle => 'catalog.bundle',
        CatalogProductType.standard || CatalogProductType.other => null,
      };

  /// Whether the line has anything to say for [product].
  static bool shows(CatalogProductEntity product) =>
      CatalogProductCard.unitKeyOf(product.unitOfSale) != null ||
      _typeKey(product) != null ||
      product.hasRating;

  @override
  Widget build(BuildContext context) {
    final unitKey = CatalogProductCard.unitKeyOf(product.unitOfSale);
    final typeKey = _typeKey(product);
    final grey = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.secondaryText,
    );
    final items = <Widget>[
      if (unitKey != null) Text(unitKey.tr(), style: grey),
      if (typeKey != null) Text(typeKey.tr(), style: grey),
      if (product.hasRating)
        PdpRatingSummary(
          rating: product.ratingAverage,
          count: product.ratingCount,
          onTap: onOpenReviews,
        ),
    ];
    return Wrap(
      spacing: AppSpacing.s6,
      runSpacing: AppSpacing.s4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) ExcludeSemantics(child: Text(_separator, style: grey)),
          item,
        ],
      ],
    );
  }
}
