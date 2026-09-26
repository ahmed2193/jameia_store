import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/shelf_tag_pill.dart';
import 'pdp_brand_link.dart';
import 'pdp_description_text.dart';
import 'pdp_info_notes.dart';
import 'pdp_meta_row.dart';

/// Top text block of the product page's sheet, talabat-mart style: the
/// merchandising tag, the brand as an underlined link, the name in bold,
/// the grey unit · kind · rating line, the description folded behind an
/// inline "More", and the compact deal / stock / Pro notes.
class PdpInfoBlock extends StatelessWidget {
  const PdpInfoBlock({
    super.key,
    required this.product,
    required this.inStock,
    this.brand,
    this.description = '',
    this.lowStockLeft,
    this.discountPercent = 0,
    this.proPriceApplied = false,
    this.proPriceHintFils,
    this.onOpenReviews,
  });

  final CatalogProductEntity product;

  /// Stock of what is selected (the chosen variant for a variant product).
  final bool inStock;
  final BrandEntity? brand;
  final String description;

  /// Units left when they are running out, else `null`.
  final int? lowStockLeft;
  final int discountPercent;
  final bool proPriceApplied;
  final int? proPriceHintFils;
  final VoidCallback? onOpenReviews;

  static const int _nameLines = 3;

  @override
  Widget build(BuildContext context) {
    final brand = this.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ShelfTagPill.wears(product)) ...[
          ShelfTagPill(product: product),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (brand != null && brand.name.isNotEmpty) ...[
          PdpBrandLink(brand: brand),
          const SizedBox(height: AppSpacing.s6),
        ],
        Text(
          product.name,
          maxLines: _nameLines,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.primaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
        if (PdpMetaRow.shows(product)) ...[
          const SizedBox(height: AppSpacing.s6),
          PdpMetaRow(product: product, onOpenReviews: onOpenReviews),
        ],
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          PdpDescriptionText(description: description),
        ],
        PdpInfoNotes(
          inStock: inStock,
          lowStockLeft: lowStockLeft,
          discountPercent: discountPercent,
          proPriceApplied: proPriceApplied,
          proPriceHintFils: proPriceHintFils,
        ),
      ],
    );
  }
}
