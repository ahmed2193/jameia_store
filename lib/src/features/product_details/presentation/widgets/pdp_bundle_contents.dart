import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../domain/entities/product_detail.dart';
import 'pdp_bundle_item_row.dart';
import 'pdp_section_card.dart';

/// What a bundle contains.
class PdpBundleContents extends StatelessWidget {
  const PdpBundleContents({
    super.key,
    required this.items,
    required this.onOpenProduct,
  });

  final List<ProductBundleItem> items;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return PdpSectionCard(
      title: 'product.bundle_contains'.tr(),
      child: Column(
        children: [
          for (final item in items)
            PdpBundleItemRow(
              key: ValueKey(item.product.id),
              item: item,
              onTap: () => onOpenProduct(item.product),
            ),
        ],
      ),
    );
  }
}
