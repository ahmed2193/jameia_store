import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import 'assistant_product_tile.dart';

/// `products`: a lazy horizontal rail of catalogue cards (one product is a
/// rail of one, never a stretched card). Scrolls from the start edge in both
/// directions of reading; the height follows the text scale.
class AssistantProductsRail extends StatelessWidget {
  const AssistantProductsRail({super.key, required this.products});

  final List<CatalogProductEntity> products;

  static const double _step = CatalogProductCard.defaultWidth + AppSpacing.s8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CatalogProductCard.cellHeight(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemExtent: _step,
        addAutomaticKeepAlives: false,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
          child: AssistantProductTile(product: products[index]),
        ),
      ),
    );
  }
}
