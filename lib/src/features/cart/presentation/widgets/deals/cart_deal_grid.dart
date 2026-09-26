import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import 'cart_deal_tile.dart';

/// The products under the selected deal, three to a row, built lazily.
class CartDealGrid extends StatelessWidget {
  const CartDealGrid({super.key, required this.products});

  final List<CatalogProductEntity> products;

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tile =
            (constraints.maxWidth -
                AppSpacing.gutter * 2 -
                AppSpacing.s8 * (_columns - 1)) /
            _columns;
        return GridView.builder(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s12,
            AppSpacing.gutter,
            AppSpacing.s16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            crossAxisSpacing: AppSpacing.s8,
            mainAxisSpacing: AppSpacing.s12,
            mainAxisExtent: CatalogProductCard.cellHeight(context, width: tile),
          ),
          itemCount: products.length,
          itemBuilder: (_, index) => CartDealTile(
            key: ValueKey<String>(products[index].id),
            product: products[index],
            width: tile,
          ),
        );
      },
    );
  }
}
