import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/offer_entity.dart';

enum CheckoutOffersStatus { loading, ready }

/// The store's offers for the checkout pages. A failed read is `ready` with
/// no offers: the cards are then built from the cart alone.
class CheckoutOffersState extends Equatable {
  const CheckoutOffersState({
    this.status = CheckoutOffersStatus.loading,
    this.offers = const <OfferEntity>[],
  });

  final CheckoutOffersStatus status;
  final List<OfferEntity> offers;

  @override
  List<Object?> get props => [status, offers];
}
