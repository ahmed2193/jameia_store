import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/shelf_product_card.dart';
import 'pdp_rail_tile.dart';
import 'pdp_section.dart';

/// A titled horizontal rail of the storefront's shelf cards under the
/// product ("Similar products", "Shop more for less"), lazily built. Cards
/// are sized from the viewport so about two and a half show, the next one
/// peeking in to say the rail scrolls.
class PdpProductRail extends StatelessWidget {
  const PdpProductRail({
    super.key,
    required this.title,
    required this.products,
  });

  final String title;
  final List<CatalogProductEntity> products;

  /// Cards in view, the last one peeking.
  static const double _cardsInView = 2.6;
  static const double _minCardWidth = 112;
  static const double _maxCardWidth = AppSize.s160;

  /// The leading gutter and the gaps between the cards in view.
  static const double _gutters =
      AppSpacing.s16 + AppSpacing.s12 + AppSpacing.s12;

  /// One card's width in a rail across [viewportWidth].
  static double cardWidthFor(double viewportWidth) =>
      ((viewportWidth - _gutters) / _cardsInView).clamp(
        _minCardWidth,
        _maxCardWidth,
      );

  @override
  Widget build(BuildContext context) {
    final width = cardWidthFor(MediaQuery.sizeOf(context).width);
    return PdpSection(
      title: title,
      padded: false,
      child: SizedBox(
        // Its tallest card, which grows with the reader's text scale.
        height: ShelfProductCard.railHeight(
          context,
          width: width,
          products: products,
          // Sized for a non-member, whose cards also carry the Pro price
          // line: the tallest case, so no card is ever cut off.
          pro: false,
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          itemCount: products.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
          itemBuilder: (context, index) => PdpRailTile(
            key: ValueKey(products[index].id),
            product: products[index],
            width: width,
          ),
        ),
      ),
    );
  }
}
