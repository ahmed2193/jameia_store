import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_layout.dart';
import 'home_product_strip.dart';
import 'home_product_tile.dart';
import 'home_reveal_item.dart';
import 'home_section_block.dart';

/// A product rail of the home feed: a lazily built horizontal strip
/// ([HomeRailLayout.slider]) or a wrapping grid ([HomeRailLayout.grid]).
/// The arrow opens the collection behind the rail.
///
/// A rail the backend themed (`deals` / `sale` / `featured`) runs on a tinted
/// band; a standard rail stays on the white page.
class HomeProductRail extends StatelessWidget {
  const HomeProductRail({
    super.key,
    required this.section,
    required this.onOpenProduct,
    required this.onViewAll,
  });

  final HomeProductRailSection section;
  final ValueChanged<CatalogProductEntity> onOpenProduct;
  final VoidCallback onViewAll;

  static const int _gridColumns = 2;

  @override
  Widget build(BuildContext context) {
    final products = section.products;
    return HomeSectionBlock(
      section: section,
      onSeeAll: section.hasViewAll ? onViewAll : null,
      fill: HomeAccentPalette.blockFill(section.theme),
      child: section.layout == HomeRailLayout.grid
          ? Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: HomeLayout.gutter,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width =
                      (constraints.maxWidth -
                          AppSpacing.s8 * (_gridColumns - 1)) /
                      _gridColumns;
                  return Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s12,
                    children: [
                      for (final (index, product) in products.indexed)
                        HomeRevealItem(
                          key: ValueKey<String>(product.id),
                          index: index,
                          axis: Axis.vertical,
                          child: HomeProductTile(
                            product: product,
                            width: width,
                            onOpen: onOpenProduct,
                            // Names of a row line up, tagged or not.
                            alignsTagLine: true,
                          ),
                        ),
                    ],
                  );
                },
              ),
            )
          : HomeProductStrip(products: products, onOpenProduct: onOpenProduct),
    );
  }
}
