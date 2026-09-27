import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/checkout_catalog_repository.dart';

/// The store's running offers, whose terms (minimum, cap, stackable,
/// branches, end) enrich the cart's offer rows on the checkout.
class GetStoreOffersUseCase implements UseCase<List<OfferEntity>, NoParams> {
  const GetStoreOffersUseCase(this._repository);
  final CheckoutCatalogRepository _repository;

  @override
  Future<Either<Failure, List<OfferEntity>>> call(NoParams params) =>
      _repository.getStoreOffers();
}
