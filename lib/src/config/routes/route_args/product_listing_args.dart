import 'package:flutter/foundation.dart';

import '../../../core/domain/entities/catalog_product_query.dart';

/// `extra` for [Routes.productListing]: one paginated product list
/// (`GET /v1/products`) scoped by [query], under [title].
///
/// A collection or a brand opens as a collection page ([isCollectionLook]):
/// a tinted hero with [title], a [flame], [subtitle] and a countdown to
/// [endsAt]. Every other list (search, a tag) keeps the plain app bar and
/// ignores the hero fields.
@immutable
class ProductListingArgs {
  const ProductListingArgs({
    required this.title,
    required this.query,
    this.subtitle = '',
    this.endsAt,
    this.flame = false,
  });

  /// The products of a brand (`brandSlug`).
  ProductListingArgs.brand({
    required String slug,
    required this.title,
    this.subtitle = '',
    this.endsAt,
    this.flame = false,
  }) : query = CatalogProductQuery(brandSlug: slug);

  /// The products of a collection (`collectionSlug`) — the "view all" of a
  /// home product rail, a promo card / strip / banner that links a collection.
  ProductListingArgs.collection({
    required String slug,
    required this.title,
    this.subtitle = '',
    this.endsAt,
    this.flame = false,
  }) : query = CatalogProductQuery(collectionSlug: slug);

  /// Already resolved for the active language by whoever opens the list.
  final String title;
  final CatalogProductQuery query;

  /// The line under the hero's heading ("Up to 30% off"); `''` = none.
  /// Already resolved for the active language.
  final String subtitle;

  /// When the offer behind the list ends (a flash sale): the hero counts
  /// down to it while it is in the future.
  final DateTime? endsAt;

  /// A sale or deals list: the Hero flame follows the hero's heading.
  final bool flame;

  /// A collection or a brand: the Hero collection page (hero, category
  /// tabs, no sort / filter toolbar). Search and tag lists stay plain.
  bool get isCollectionLook =>
      _isSet(query.collectionSlug) || _isSet(query.brandSlug);

  static bool _isSet(String? slug) => slug != null && slug.isNotEmpty;
}
