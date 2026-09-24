import 'package:flutter/foundation.dart';

import '../../../core/domain/entities/catalog_product_query.dart';

/// `extra` for [Routes.productListing]: one paginated product list
/// (`GET /v1/products`) scoped by [query], under [title].
@immutable
class ProductListingArgs {
  const ProductListingArgs({required this.title, required this.query});

  /// The products of a brand (`brandSlug`).
  ProductListingArgs.brand({required String slug, required this.title})
    : query = CatalogProductQuery(brandSlug: slug);

  /// The products of a collection (`collectionSlug`) — the "view all" of a
  /// home product rail, a promo card / strip / banner that links a collection.
  ProductListingArgs.collection({required String slug, required this.title})
    : query = CatalogProductQuery(collectionSlug: slug);

  /// Already resolved for the active language by whoever opens the list.
  final String title;
  final CatalogProductQuery query;
}
