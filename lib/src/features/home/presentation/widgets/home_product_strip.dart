import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import 'home_product_tile.dart';

/// The horizontal row of product cards every home block uses — a plain rail
/// and the themed deals block alike, so the two can never drift apart. The
/// cards are the app's one shared product card.
class HomeProductStrip extends StatelessWidget {
  const HomeProductStrip({
    super.key,
    required this.products,
    required this.onOpenProduct,
    this.gutter = AppSpacing.pageMargin,
  });

  final List<CatalogProductEntity> products;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  /// Padding before the first and after the last card. A themed block is
  /// already inset from the page, so it passes a smaller one.
  final double gutter;

  static const double cardWidth = CatalogProductCard.defaultWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // The square image plus the card's text block, which grows with the
      // reader's text scale.
      height: CatalogProductCard.cellHeight(context, width: cardWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
        itemCount: products.length,
        // Tiles isolate their own repaints; keep-alives would pin every
        // off-screen card of every rail in memory.
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) => HomeProductTile(
          key: ValueKey<String>(products[index].id),
          product: products[index],
          width: cardWidth,
          onOpen: onOpenProduct,
        ),
      ),
    );
  }
}
