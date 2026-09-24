import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// The products loaded so far for one [CatalogProductQuery] — pages of
/// `GET /v1/products` merged in order. Owns the list maths so the cubits of
/// every listing (category, brand, collection, search, offers) only sequence
/// calls.
class CatalogProductsPage extends Equatable {
  const CatalogProductsPage({
    required this.products,
    required this.page,
    required this.hasMore,
    required this.total,
  });

  static const CatalogProductsPage empty = CatalogProductsPage(
    products: <CatalogProductEntity>[],
    page: 0,
    hasMore: false,
    total: 0,
  );

  final List<CatalogProductEntity> products;

  /// Last page merged in (1-based); `0` before the first load.
  final int page;
  final bool hasMore;

  /// Matches on the server, across all pages.
  final int total;

  bool get isEmpty => products.isEmpty;

  /// Appends [next] (a later page), dropping products already shown — the
  /// backend list can shift between two requests.
  CatalogProductsPage merge(CatalogProductsPage next) {
    final known = {for (final product in products) product.id};
    return CatalogProductsPage(
      products: [
        ...products,
        ...next.products.where((product) => !known.contains(product.id)),
      ],
      page: next.page,
      hasMore: next.hasMore,
      total: next.total,
    );
  }

  @override
  List<Object?> get props => [products, page, hasMore, total];
}
