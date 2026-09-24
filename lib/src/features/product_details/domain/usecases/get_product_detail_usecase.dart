import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_detail.dart';
import '../repositories/product_details_repository.dart';

class GetProductDetailParams extends Equatable {
  const GetProductDetailParams(this.slug);

  final String slug;

  @override
  List<Object?> get props => [slug];
}

/// Loads a product page (`GET /v1/products/:slug`).
class GetProductDetailUseCase
    implements UseCase<ProductDetail, GetProductDetailParams> {
  const GetProductDetailUseCase(this._repository);

  final ProductDetailsRepository _repository;

  @override
  Future<Either<Failure, ProductDetail>> call(GetProductDetailParams params) =>
      _repository.getProduct(params.slug);
}
