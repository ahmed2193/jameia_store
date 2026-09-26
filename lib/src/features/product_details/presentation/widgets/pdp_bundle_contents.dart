import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../domain/entities/product_detail.dart';
import 'pdp_bundle_item_row.dart';
import 'pdp_section.dart';

/// What a bundle contains: flat rows split by hairlines.
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
    return PdpSection(
      title: 'product.bundle_contains'.tr(),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const ThinDivider(),
            PdpBundleItemRow(
              key: ValueKey(items[i].product.id),
              item: items[i],
              onTap: () => onOpenProduct(items[i].product),
            ),
          ],
        ],
      ),
    );
  }
}
