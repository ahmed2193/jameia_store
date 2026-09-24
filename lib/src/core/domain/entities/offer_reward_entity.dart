import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';

/// What an offer gives (`reward.type`).
enum OfferRewardType {
  freeDelivery,
  percentageDiscount,
  fixedDiscount,
  freeProduct,
  other,
}

/// The reward of a cart offer, as `appliedOffers[].reward` /
/// `offerProgress[].reward` send it: a tagged union flattened to optional
/// fields, [type] says which apply.
class OfferRewardEntity extends Equatable {
  const OfferRewardEntity({
    this.type = OfferRewardType.other,
    this.percent = 0,
    this.maxDiscountFils,
    this.amountFils = 0,
    this.productId,
    this.quantity = 0,
  });

  final OfferRewardType type;

  /// [OfferRewardType.percentageDiscount]: whole percent off.
  final int percent;
  final int? maxDiscountFils;

  /// [OfferRewardType.fixedDiscount]: fils off.
  final int amountFils;

  /// [OfferRewardType.freeProduct]: what is added for free.
  final String? productId;
  final int quantity;

  double get amountKd => amountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    type,
    percent,
    maxDiscountFils,
    amountFils,
    productId,
    quantity,
  ];
}
