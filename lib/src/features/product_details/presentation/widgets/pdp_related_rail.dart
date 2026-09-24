import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import 'pdp_related_tile.dart';
import 'pdp_section_card.dart';

/// "Related products": a lazily built horizontal strip of product cards.
class PdpRelatedRail extends StatelessWidget {
  const PdpRelatedRail({
    super.key,
    required this.products,
    required this.pro,
    required this.onOpenProduct,
  });

  final List<CatalogProductEntity> products;
  final bool pro;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return PdpSectionCard(
      title: 'product.related_products'.tr(),
      padded: false,
      child: SizedBox(
        // Follows the card, which grows with the reader's text scale.
        height: CatalogProductCard.cellHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          itemCount: products.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (context, index) => PdpRelatedTile(
            key: ValueKey(products[index].id),
            product: products[index],
            pro: pro,
            onOpen: onOpenProduct,
          ),
        ),
      ),
    );
  }
}
