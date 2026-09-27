import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import 'pdp_brand_link.dart';
import 'pdp_description_text.dart';
import 'pdp_meta_row.dart';
import 'pdp_stock_note.dart';
import 'pdp_tag_chips.dart';

/// Top text block of the product page's sheet, Hero style: the
/// merchandising tags as flat grey chips, the brand as an underlined link,
/// the name in bold, the grey unit · kind · rating line, the description
/// folded behind an inline "More", and how the stock stands when it matters
/// ("Only 3 left", out of stock). The deal and the Pro price live in the buy
/// bar, next to the price they change.
class PdpInfoBlock extends StatelessWidget {
  const PdpInfoBlock({
    super.key,
    required this.product,
    required this.inStock,
    this.brand,
    this.description = '',
    this.lowStockLeft,
    this.onOpenReviews,
  });

  final CatalogProductEntity product;

  /// Stock of what is selected (the chosen variant for a variant product).
  final bool inStock;
  final BrandEntity? brand;
  final String description;

  /// Units left when they are running out, else `null`.
  final int? lowStockLeft;
  final VoidCallback? onOpenReviews;

  static const int _nameLines = 3;

  @override
  Widget build(BuildContext context) {
    final brand = this.brand;
    final tags = product.merchTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty) ...[
          PdpTagChips(tags: tags),
          const SizedBox(height: AppSpacing.s16),
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
        if (PdpStockNote.shows(inStock: inStock, lowStockLeft: lowStockLeft))
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
            child: PdpStockNote(inStock: inStock, lowStockLeft: lowStockLeft),
          ),
      ],
    );
  }
}
