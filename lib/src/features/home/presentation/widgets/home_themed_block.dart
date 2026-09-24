import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_product_strip.dart';
import 'home_promo_strip_card.dart';
import 'home_section_block.dart';

/// A promo strip and the rail it advertises as one tinted card: the call-out
/// on top, then the rail's own header, then its products. The deal and the
/// products it is about stop being two unrelated blocks.
class HomeThemedBlock extends StatelessWidget {
  const HomeThemedBlock({
    super.key,
    required this.section,
    required this.onOpenStrip,
    required this.onOpenProduct,
    required this.onViewAll,
  });

  final HomeThemedBlockSection section;
  final VoidCallback onOpenStrip;
  final ValueChanged<CatalogProductEntity> onOpenProduct;
  final VoidCallback onViewAll;

  /// The block is already inset from the page, so its contents sit closer in.
  static const double _gutter = AppSpacing.s10;

  @override
  Widget build(BuildContext context) {
    return HomeSectionBlock(
      section: section,
      onSeeAll: section.rail.hasViewAll ? onViewAll : null,
      fill: HomeAccentPalette.blockFill(section.theme),
      inset: true,
      leading: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: _gutter),
        child: HomePromoStripCard(section: section.strip, onTap: onOpenStrip),
      ),
      child: HomeProductStrip(
        products: section.rail.products,
        onOpenProduct: onOpenProduct,
        gutter: _gutter,
      ),
    );
  }
}
