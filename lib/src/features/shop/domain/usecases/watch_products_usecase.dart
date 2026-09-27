import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/catalog_browse_repository.dart';
import 'get_products_usecase.dart';

class WatchProductsParams extends Equatable {
  const WatchProductsParams({
    required this.query,
    this.limit = GetProductsParams.defaultPageSize,
    this.forceRefresh = false,
  });

  final CatalogProductQuery query;
  final int limit;

  /// Pull to refresh / reconnect: skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [query, limit, forceRefresh];
}

/// The first page of a product listing (`GET /v1/products`): the copy saved
/// on the device first, then the server's; failures on the error channel.
/// The next pages are [GetProductsUseCase]'s — never kept. Keeps the request
/// inside the backend's bounds like it.
class WatchProductsUseCase
    implements
        StreamUseCase<DataSnapshot<CatalogProductsPage>, WatchProductsParams> {
  const WatchProductsUseCase(this._repository);

  final CatalogBrowseRepository _repository;

  @override
  Stream<DataSnapshot<CatalogProductsPage>> call(WatchProductsParams params) =>
      _repository.watchFirstPage(
        query: params.query,
        limit: params.limit.clamp(1, CatalogProductQuery.maxPageSize),
        forceRefresh: params.forceRefresh,
      );
}
