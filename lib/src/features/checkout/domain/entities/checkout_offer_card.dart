import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_offer_progress_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/offer_reward_entity.dart';

/// One ticket of the "Coupons & offers" page: an offer the cart already
/// applied ([isApplied], with what it saved) or one the basket is working
/// towards (with what is missing). Built from the cart and, when the store's
/// offer list knows it, enriched with its terms (minimum, cap, stackable,
/// end). No "best offer" flag: the API does not rank offers.
class CheckoutOfferCard extends Equatable {
  const CheckoutOfferCard({
    required this.offerId,
    required this.name,
    this.kind = OfferProgressKind.other,
    this.rewardType = OfferRewardType.other,
    this.percent = 0,
    this.amountFils = 0,
    this.maxDiscountFils,
    this.minSubtotalFils = 0,
    this.minQuantity = 0,
    this.contextId,
    this.contextName,
    this.rewardProductName,
    this.stackable,
    this.endsAt,
    this.savedFils,
    this.remainingValue = 0,
    this.remainingIsFils = true,
    this.fraction = 0,
  });

  final String offerId;

  /// Server-localized.
  final String name;

  /// What a locked offer counts (subtotal, one product, one category).
  final OfferProgressKind kind;
  final OfferRewardType rewardType;
  final int percent;
  final int amountFils;
  final int? maxDiscountFils;

  /// A subtotal offer's minimum (from the offer list; `0` when unknown).
  final int minSubtotalFils;

  /// An item / category offer's minimum pieces (`0` when unknown).
  final int minQuantity;

  /// The product / category a locked offer counts.
  final String? contextId;
  final String? contextName;

  /// A free-product reward's product name.
  final String? rewardProductName;

  /// `null` when the offer list does not know the offer.
  final bool? stackable;
  final DateTime? endsAt;

  /// What an applied offer saved; `null` while locked.
  final int? savedFils;

  /// What is still missing: fils when [remainingIsFils], pieces otherwise.
  final int remainingValue;
  final bool remainingIsFils;

  /// 0..1 progress of a locked offer.
  final double fraction;

  bool get isApplied => savedFils != null;

  /// It cannot be combined with the offers the basket already gets, so the
  /// basket only "qualifies" for it (never "unlocks" it on top).
  bool get qualifiesOnly => stackable == false;

  double get amountKd => amountFils / CatalogProductEntity.filsPerDinar;
  double? get maxDiscountKd {
    final cap = maxDiscountFils;
    return cap == null ? null : cap / CatalogProductEntity.filsPerDinar;
  }

  double get minSubtotalKd =>
      minSubtotalFils / CatalogProductEntity.filsPerDinar;
  double? get savedKd {
    final saved = savedFils;
    return saved == null ? null : saved / CatalogProductEntity.filsPerDinar;
  }

  /// [remainingValue] in dinar (fils kinds only).
  double get remainingKd => remainingValue / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    offerId,
    name,
    kind,
    rewardType,
    percent,
    amountFils,
    maxDiscountFils,
    minSubtotalFils,
    minQuantity,
    contextId,
    contextName,
    rewardProductName,
    stackable,
    endsAt,
    savedFils,
    remainingValue,
    remainingIsFils,
    fraction,
  ];
}
