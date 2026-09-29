import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/shelf_product_card.dart';
import 'listing_product_tile.dart';

/// The product grid of a listing as a lazily built sliver: two columns on a
/// phone, more as the screen widens. The cell height follows the card
/// ([ShelfProductCard.cellHeight]), so nothing is measured. The first cards
/// come in one after another as the listing first arrives
/// ([EntranceCascadeItem], after [firstRevealIndex] pieces above the grid).
class ProductGridSliver extends StatelessWidget {
  const ProductGridSliver({
    super.key,
    required this.products,
    this.firstRevealIndex = 0,
  });

  final List<CatalogProductEntity> products;

  /// Where the first card sits in the listing's entrance order.
  final int firstRevealIndex;

  static const double _targetCellWidth = AppSize.s180;
  static const int _minColumns = 2;
  static const int _maxColumns = 6;

  /// Space between two cells, across and down.
  static const double crossGap = AppSpacing.s12;
  static const double mainGap = AppSpacing.s20;

  /// Around the grid: 16 dp gutters, a little air above and below.
  static const EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.s16,
    AppSpacing.s8,
    AppSpacing.s16,
    AppSpacing.s8,
  );

  /// Columns for a grid [width] wide (inside [padding]).
  static int columnsFor(double width) =>
      (width / _targetCellWidth).floor().clamp(_minColumns, _maxColumns);

  /// Width of one cell of a [columns]-column grid [width] wide.
  static double cellWidthFor(double width, int columns) =>
      (width - crossGap * (columns - 1)) / columns;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.crossAxisExtent;
          final columns = columnsFor(available);
          final cellWidth = cellWidthFor(available, columns);
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: crossGap,
              mainAxisSpacing: mainGap,
              mainAxisExtent: ShelfProductCard.cellHeight(
                context,
                width: cellWidth,
              ),
            ),
            itemCount: products.length,
            // Tiles isolate their own repaints (see [ListingProductTile]).
            addRepaintBoundaries: false,
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) => EntranceCascadeItem(
              key: ValueKey<String>(products[index].id),
              index: firstRevealIndex + index,
              child: ListingProductTile(
                product: products[index],
                width: cellWidth,
              ),
            ),
          );
        },
      ),
    );
  }
}
