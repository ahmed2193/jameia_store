import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/rating_badge.dart';
import 'pdp_info_chip.dart';
import 'pdp_section_card.dart';

/// Top text block of the product page: unit of sale, type and stock chips,
/// the name, the description and the rating summary.
class PdpHeaderBlock extends StatelessWidget {
  const PdpHeaderBlock({
    super.key,
    required this.product,
    required this.inStock,
    this.description = '',
    this.onOpenReviews,
  });

  final CatalogProductEntity product;

  /// Stock of what is selected (the chosen variant for a variant product).
  final bool inStock;
  final String description;
  final VoidCallback? onOpenReviews;

  @override
  Widget build(BuildContext context) {
    final unitKey = switch (product.unitOfSale) {
      UnitOfSale.piece => 'catalog.per_piece',
      UnitOfSale.kg => 'catalog.per_kg',
      UnitOfSale.litre => 'catalog.per_litre',
      UnitOfSale.pack => 'catalog.per_pack',
      UnitOfSale.other => null,
    };
    final typeKey = switch (product.type) {
      CatalogProductType.variant => 'catalog.multiple_sizes',
      CatalogProductType.bundle => 'catalog.bundle',
      CatalogProductType.standard || CatalogProductType.other => null,
    };
    return PdpSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              if (unitKey != null)
                PdpInfoChip(
                  label: unitKey.tr(),
                  foreground: AppColors.labelGrey,
                  background: AppColors.smallBackground,
                ),
              if (typeKey != null)
                PdpInfoChip(
                  label: typeKey.tr(),
                  foreground: AppColors.labelGrey,
                  background: AppColors.smallBackground,
                ),
              PdpInfoChip(
                label: inStock
                    ? 'product.in_stock'.tr()
                    : 'catalog.out_of_stock'.tr(),
                foreground: inStock ? AppColors.success : AppColors.error,
                background: inStock ? AppColors.successBg : AppColors.errorBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            product.name,
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
          if (product.hasRating) ...[
            const SizedBox(height: AppSpacing.s8),
            GestureDetector(
              onTap: onOpenReviews,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RatingBadge(rating: product.ratingAverage),
                  const SizedBox(width: AppSpacing.s6),
                  Text(
                    'product.reviews_count'.tr(
                      namedArgs: {'count': '${product.ratingCount}'},
                    ),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.link,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
