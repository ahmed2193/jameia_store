import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/product_details_repository.dart';

class GetProductOfferParams extends Equatable {
  const GetProductOfferParams({
    required this.productId,
    this.categoryIds = const <String>[],
    this.now,
  });

  final String productId;

  /// The product's category and its parent (`ProductDetail.offerCategoryIds`).
  final List<String> categoryIds;

  /// The clock of the "still running" rule; `DateTime.now()` when null.
  final DateTime? now;

  @override
  List<Object?> get props => [productId, categoryIds, now];
}

/// The cart offer the product page advertises over its price ("2 KWD off
/// dairy (3 items)"): the backend's highest-priority live offer that counts
/// this product itself or its category. A subtotal offer counts every
/// product, so it is never the product's own. `Right(null)` when none does.
class GetProductOfferUseCase
    implements UseCase<OfferEntity?, GetProductOfferParams> {
  const GetProductOfferUseCase(this._repository);

  final ProductDetailsRepository _repository;

  @override
  Future<Either<Failure, OfferEntity?>> call(
    GetProductOfferParams params,
  ) async {
    final now = params.now ?? DateTime.now();
    return (await _repository.getOffers()).map((offers) {
      for (final offer in offers) {
        if (offer.isLiveAt(now) &&
            offer.countsProduct(params.productId, params.categoryIds)) {
          return offer;
        }
      }
      return null;
    });
  }
}
