import 'package:flutter/foundation.dart';

import '../../../core/domain/entities/catalog_product_entity.dart';

/// `extra` for [Routes.productDetail]. The product is addressed by [slug]
/// (`GET /v1/products/:slug`); [preview] is the list card the customer tapped,
/// so the page can paint name / image / price while the detail loads.
@immutable
class ProductDetailArgs {
  const ProductDetailArgs({required this.slug, this.preview});

  /// Opens the page from a product card.
  ProductDetailArgs.of(CatalogProductEntity product)
    : slug = product.slug,
      preview = product;

  final String slug;
  final CatalogProductEntity? preview;
}
