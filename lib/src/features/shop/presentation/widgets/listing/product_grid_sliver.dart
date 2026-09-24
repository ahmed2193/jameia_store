import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import 'listing_product_tile.dart';

/// The product grid of a listing as a lazily built sliver: two columns on a
/// phone, more as the screen widens. The cell height follows the card
/// ([CatalogProductCard.cellHeight]), so nothing is measured.
class ProductGridSliver extends StatelessWidget {
  const ProductGridSliver({super.key, required this.products});

  final List<CatalogProductEntity> products;

  static const double _targetCellWidth = AppSize.s180;
  static const int _minColumns = 2;
  static const int _maxColumns = 6;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        AppSpacing.s8,
        AppSpacing.pageMargin,
        AppSpacing.s8,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.crossAxisExtent;
          final columns = (available / _targetCellWidth).floor().clamp(
            _minColumns,
            _maxColumns,
          );
          final cellWidth =
              (available - AppSpacing.s8 * (columns - 1)) / columns;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.s8,
              mainAxisSpacing: AppSpacing.s12,
              mainAxisExtent: CatalogProductCard.cellHeight(
                context,
                width: cellWidth,
              ),
            ),
            itemCount: products.length,
            // Tiles isolate their own repaints (see [ListingProductTile]).
            addRepaintBoundaries: false,
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) => ListingProductTile(
              key: ValueKey<String>(products[index].id),
              product: products[index],
              width: cellWidth,
            ),
          );
        },
      ),
    );
  }
}
