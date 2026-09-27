import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/offer_reward_entity.dart';

/// The nearest reward the basket can still unlock by spending more: how
/// much is missing and what the reward is (its text is built from the
/// reward, never from the offer's name).
class CheckoutUnlock extends Equatable {
  const CheckoutUnlock({
    required this.offerId,
    required this.remainingFils,
    required this.rewardType,
    this.percent = 0,
    this.amountFils = 0,
    this.maxDiscountFils,
  });

  final String offerId;

  /// What the subtotal is still short of.
  final int remainingFils;
  final OfferRewardType rewardType;

  /// [OfferRewardType.percentageDiscount].
  final int percent;

  /// [OfferRewardType.fixedDiscount].
  final int amountFils;

  /// Cap of a percentage discount, when there is one.
  final int? maxDiscountFils;

  double get remainingKd => remainingFils / CatalogProductEntity.filsPerDinar;
  double get amountKd => amountFils / CatalogProductEntity.filsPerDinar;
  double? get maxDiscountKd {
    final cap = maxDiscountFils;
    return cap == null ? null : cap / CatalogProductEntity.filsPerDinar;
  }

  @override
  List<Object?> get props => [
    offerId,
    remainingFils,
    rewardType,
    percent,
    amountFils,
    maxDiscountFils,
  ];
}
