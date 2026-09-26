import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_campaign_header.dart';
import 'home_layout.dart';
import 'home_product_strip.dart';

/// A promo strip and the rail it advertises as one campaign band, edge to
/// edge in the theme's light wash: the campaign header, then its products.
/// The header's arrow opens the collection the rail is a preview of — the
/// backend joins the two on that collection, so it is the rail's "view all"
/// as well.
class HomeThemedBlock extends StatelessWidget {
  const HomeThemedBlock({
    super.key,
    required this.section,
    required this.onOpenStrip,
    required this.onOpenProduct,
  });

  final HomeThemedBlockSection section;
  final VoidCallback onOpenStrip;
  final ValueChanged<CatalogProductEntity> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HomeAccentPalette.blockFill(section.theme),
      margin: const EdgeInsetsDirectional.only(bottom: HomeLayout.blockGap),
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCampaignHeader(strip: section.strip, onTap: onOpenStrip),
          const SizedBox(height: AppSpacing.s14),
          HomeProductStrip(
            products: section.rail.products,
            onOpenProduct: onOpenProduct,
          ),
        ],
      ),
    );
  }
}
