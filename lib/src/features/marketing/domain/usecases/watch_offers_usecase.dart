import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/promotions_repository.dart';

class WatchOffersParams extends Equatable {
  const WatchOffersParams({required this.now, this.forceRefresh = false});

  /// Offers that already ended at [now] are left out.
  final DateTime now;

  /// Pull to refresh / reconnect: skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [now, forceRefresh];
}

/// The offers the customer can benefit from right now (`GET /v1/offers`):
/// the copy saved on the device first, then the server's. An offer that has
/// ended is left out of both — a saved copy never shows an expired offer.
class WatchOffersUseCase
    implements
        StreamUseCase<DataSnapshot<List<OfferEntity>>, WatchOffersParams> {
  const WatchOffersUseCase(this._repository);

  final PromotionsRepository _repository;

  @override
  Stream<DataSnapshot<List<OfferEntity>>> call(WatchOffersParams params) =>
      _repository
          .watchOffers(forceRefresh: params.forceRefresh)
          .map(
            (snapshot) => snapshot.map(
              (offers) => [
                for (final offer in offers)
                  if (offer.isLiveAt(params.now)) offer,
              ],
            ),
          );
}
