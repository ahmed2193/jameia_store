import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/cart_repository.dart';

/// `+1` / `-1` on a product tile or a cart line; applies at once, syncs
/// later. A variant product must name the variant.
class AdjustCartLineUseCase implements SyncUseCase<Unit, AdjustCartLineParams> {
  const AdjustCartLineUseCase(this._repository);
  final CartRepository _repository;

  @override
  Either<Failure, Unit> call(AdjustCartLineParams params) {
    if (params.delta == 0) return const Right(unit);
    if (params.product.isVariant && params.variantId == null) {
      return const Left(ValidationFailure('variant required'));
    }
    return _repository.adjustLine(
      product: params.product,
      variantId: params.variantId,
      delta: params.delta,
    );
  }
}

class AdjustCartLineParams extends Equatable {
  const AdjustCartLineParams({
    required this.product,
    this.variantId,
    this.delta = 1,
  });

  final CatalogProductEntity product;
  final String? variantId;
  final int delta;

  @override
  List<Object?> get props => [product, variantId, delta];
}
