import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_product_strip.dart';
import 'home_product_tile.dart';
import 'home_section_block.dart';

/// A product rail of the home feed: a lazily built horizontal strip
/// ([HomeRailLayout.slider]) or a wrapping grid ([HomeRailLayout.grid]).
/// "View all" opens the collection behind the rail.
///
/// A rail the backend themed (`deals` / `sale` / `featured`) becomes a tinted
/// card inset from the page; a standard rail stays a white band.
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

  /// Gutter inside a themed block, which is already inset from the page.
  static const double _insetGutter = AppSpacing.s10;

  @override
  Widget build(BuildContext context) {
    final products = section.products;
    final isThemed = section.theme != HomeSectionTheme.standard;
    final gutter = isThemed ? _insetGutter : AppSpacing.pageMargin;
    return HomeSectionBlock(
      section: section,
      onSeeAll: section.hasViewAll ? onViewAll : null,
      fill: HomeAccentPalette.blockFill(section.theme),
      inset: isThemed,
      child: section.layout == HomeRailLayout.grid
          ? Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
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
                      for (final product in products)
                        HomeProductTile(
                          key: ValueKey<String>(product.id),
                          product: product,
                          width: width,
                          onOpen: onOpenProduct,
                        ),
                    ],
                  );
                },
              ),
            )
          : HomeProductStrip(
              products: products,
              onOpenProduct: onOpenProduct,
              gutter: gutter,
            ),
    );
  }
}
