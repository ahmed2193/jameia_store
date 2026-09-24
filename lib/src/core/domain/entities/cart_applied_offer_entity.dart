import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';
import 'offer_reward_entity.dart';

/// An offer the server already applied to the cart
/// (`GET /v1/cart` → `appliedOffers[]`). [name] arrives resolved for the
/// request language.
class CartAppliedOfferEntity extends Equatable {
  const CartAppliedOfferEntity({
    required this.offerId,
    required this.name,
    this.discountFils = 0,
    this.reward = const OfferRewardEntity(),
  });

  final String offerId;
  final String name;
  final int discountFils;
  final OfferRewardEntity reward;

  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [offerId, name, discountFils, reward];
}
