import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import 'checkout_rail_tile.dart';

/// The rail's cards, side by side: the app's 130 dp shelf card (the size
/// the home and cart rails decode, so the pictures are cache hits) with an
/// 8 dp gap, from the 12 dp gutter. At 360 dp a third card peeks in, which
/// says the rail scrolls. Built lazily at a fixed extent; no cascade, no
/// auto-scroll.
class CheckoutRailList extends StatelessWidget {
  const CheckoutRailList({super.key, required this.products});

  static const double _extent = CatalogProductCard.defaultWidth + AppSpacing.s8;

  final List<CatalogProductEntity> products;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.s12,
        end: AppSpacing.s4,
      ),
      itemExtent: _extent,
      itemCount: products.length,
      // The extent is the card plus its gap: the card keeps its own width
      // at the start of its cell.
      itemBuilder: (_, index) => Align(
        alignment: AlignmentDirectional.topStart,
        child: CheckoutRailTile(product: products[index]),
      ),
    );
  }
}
