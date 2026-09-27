import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/checkout_catalog_repository.dart';

class GetRailProductsParams extends Equatable {
  const GetRailProductsParams({
    this.excludeProductIds = const <String>{},
    this.limit = defaultLimit,
  });

  /// The rail never shows more cards than this.
  static const int defaultLimit = 10;

  /// Products already in the basket (taken once when the page opens).
  final Set<String> excludeProductIds;
  final int limit;

  @override
  List<Object?> get props => [excludeProductIds, limit];
}

/// The "deals you might have missed" rail: products on sale and in stock
/// that are not in the basket, each once, only ones the card can price
/// (a variant product lists at `price: 0`).
class GetRailProductsUseCase
    implements UseCase<List<CatalogProductEntity>, GetRailProductsParams> {
  const GetRailProductsUseCase(this._repository);
  final CheckoutCatalogRepository _repository;

  /// Read a little more than the rail shows: in-cart and unpriced products
  /// are dropped after the read.
  static const int fetchLimit = 20;

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> call(
    GetRailProductsParams params,
  ) async =>
      (await _repository.getRailProducts(limit: fetchLimit)).map((products) {
        final seen = <String>{};
        final rail = <CatalogProductEntity>[];
        for (final product in products) {
          if (rail.length >= params.limit) break;
          if (params.excludeProductIds.contains(product.id) ||
              !product.hasListPrice ||
              !product.inStock ||
              !seen.add(product.id)) {
            continue;
          }
          rail.add(product);
        }
        return rail;
      });
}
