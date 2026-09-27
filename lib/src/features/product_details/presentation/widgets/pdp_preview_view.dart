import 'package:flutter/material.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import 'pdp_info_block.dart';
import 'pdp_scaffold_view.dart';
import 'pdp_section.dart';

/// The card the customer tapped (photo, name, price), painted in the page's
/// own frame until the product arrives — and kept when it cannot arrive
/// (offline), with [footer] saying so under it.
class PdpPreviewView extends StatelessWidget {
  const PdpPreviewView({
    super.key,
    required this.preview,
    required this.footer,
    this.galleryKey,
  });

  final CatalogProductEntity preview;

  /// A loader while the product loads; the reason and "Try again" after.
  final Widget footer;

  /// On the gallery: where the buy bar's fly-to-cart takes off.
  final GlobalKey? galleryKey;

  @override
  Widget build(BuildContext context) => PdpScaffoldView(
    productSlug: preview.slug,
    title: preview.name,
    images: [if (preview.image.isNotEmpty) preview.image],
    galleryKey: galleryKey,
    sections: [
      PdpSection(
        child: PdpInfoBlock(product: preview, inStock: preview.inStock),
      ),
      footer,
    ],
  );
}
