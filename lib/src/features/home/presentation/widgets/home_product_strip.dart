import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import 'home_layout.dart';
import 'home_product_tile.dart';

/// The horizontal row of product cards every home block uses — a plain rail
/// and the campaign band alike, so the two can never drift apart. The cards
/// are the app's one shared product card.
class HomeProductStrip extends StatelessWidget {
  const HomeProductStrip({
    super.key,
    required this.products,
    required this.onOpenProduct,
    this.gutter = HomeLayout.gutter,
  });

  final List<CatalogProductEntity> products;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  /// Padding before the first and after the last card.
  final double gutter;

  static const double cardWidth = CatalogProductCard.defaultWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // The square image plus the tallest card's text, which grows with the
      // reader's text scale.
      height: CatalogProductCard.railHeight(
        context,
        width: cardWidth,
        products: products,
        // Sized for a non-member, whose cards also carry the Pro price
        // line: the tallest case, so no card is ever cut off.
        pro: false,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
        itemCount: products.length,
        // Tiles isolate their own repaints; keep-alives would pin every
        // off-screen card of every rail in memory.
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) => EntranceCascadeItem(
          key: ValueKey<String>(products[index].id),
          index: index,
          child: HomeProductTile(
            product: products[index],
            width: cardWidth,
            onOpen: onOpenProduct,
          ),
        ),
      ),
    );
  }
}
