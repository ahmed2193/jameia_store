import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_deals_repository.dart';

class GetDealProductsParams extends Equatable {
  const GetDealProductsParams({this.categoryId, this.limit = defaultLimit});

  /// The first page fills the sheet's grid a few rows deep.
  static const int defaultLimit = 30;

  /// The category a category offer counts (`CartDealEntity.categoryId`);
  /// `null` = the store's products on sale.
  final String? categoryId;
  final int limit;

  @override
  List<Object?> get props => [categoryId, limit];
}

/// The products the "Buy more, save more" sheet offers under a deal.
class GetDealProductsUseCase
    implements UseCase<List<CatalogProductEntity>, GetDealProductsParams> {
  const GetDealProductsUseCase(this._repository);

  final CartDealsRepository _repository;

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> call(
    GetDealProductsParams params,
  ) => _repository.getDealProducts(
    categoryId: params.categoryId,
    limit: params.limit,
  );
}
