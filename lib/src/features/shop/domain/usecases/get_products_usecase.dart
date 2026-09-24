import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/domain/entities/catalog_products_page.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/catalog_browse_repository.dart';

class GetProductsParams extends Equatable {
  const GetProductsParams({
    required this.query,
    required this.page,
    this.limit = defaultPageSize,
  });

  static const int defaultPageSize = 20;

  final CatalogProductQuery query;

  /// 1-based.
  final int page;
  final int limit;

  @override
  List<Object?> get props => [query, page, limit];
}

/// Loads one page of a product listing (`GET /v1/products`). Keeps the request
/// inside the backend's bounds instead of letting it answer `400`.
class GetProductsUseCase
    implements UseCase<CatalogProductsPage, GetProductsParams> {
  const GetProductsUseCase(this._repository);

  final CatalogBrowseRepository _repository;

  @override
  Future<Either<Failure, CatalogProductsPage>> call(GetProductsParams params) =>
      _repository.getProducts(
        query: params.query,
        page: params.page < 1 ? 1 : params.page,
        limit: params.limit.clamp(1, CatalogProductQuery.maxPageSize),
      );
}
