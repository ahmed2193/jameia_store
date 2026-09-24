import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/offer_entity.dart';
import '../repositories/promotions_repository.dart';

class GetOffersParams extends Equatable {
  const GetOffersParams({required this.now});

  /// Offers that already ended at [now] are left out.
  final DateTime now;

  @override
  List<Object?> get props => [now];
}

/// The offers the customer can benefit from right now (`GET /v1/offers`).
class GetOffersUseCase implements UseCase<List<OfferEntity>, GetOffersParams> {
  const GetOffersUseCase(this._repository);

  final PromotionsRepository _repository;

  @override
  Future<Either<Failure, List<OfferEntity>>> call(
    GetOffersParams params,
  ) async => (await _repository.getOffers()).map(
    (offers) => [
      for (final offer in offers)
        if (offer.isLiveAt(params.now)) offer,
    ],
  );
}
