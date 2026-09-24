import 'package:equatable/equatable.dart';

/// What the cart must contain for an offer to apply.
enum OfferTriggerType { cartSubtotal, itemQuantity, categoryQuantity, other }

/// What the customer gets.
enum OfferRewardType {
  freeDelivery,
  percentageDiscount,
  fixedDiscount,
  freeProduct,
  other,
}

/// An automatic cart promotion of the backend (`GET /v1/offers`): "spend 5 KWD
/// → free delivery", "10% off over 15 KWD"… The backend applies it to the cart
/// by itself; the app only explains it. Text arrives already resolved for the
/// request language; money is fils.
class OfferEntity extends Equatable {
  const OfferEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.triggerType = OfferTriggerType.other,
    this.minSubtotalFils = 0,
    this.minQuantity = 0,
    this.rewardType = OfferRewardType.other,
    this.percent = 0,
    this.maxDiscountFils,
    this.amountFils = 0,
    this.freeQuantity = 0,
    this.stackable = false,
    this.endsAt,
  });

  static const int filsPerDinar = 1000;

  final String id;
  final String name;
  final String description;
  final OfferTriggerType triggerType;

  /// [OfferTriggerType.cartSubtotal]: spend at least this much.
  final int minSubtotalFils;

  /// [OfferTriggerType.itemQuantity] / [OfferTriggerType.categoryQuantity].
  final int minQuantity;
  final OfferRewardType rewardType;

  /// [OfferRewardType.percentageDiscount].
  final int percent;

  /// Cap of a percentage discount, when the backend set one.
  final int? maxDiscountFils;

  /// [OfferRewardType.fixedDiscount].
  final int amountFils;

  /// [OfferRewardType.freeProduct]: how many units.
  final int freeQuantity;

  /// Combines with other offers.
  final bool stackable;
  final DateTime? endsAt;

  double get minSubtotalKd => minSubtotalFils / filsPerDinar;
  double get amountKd => amountFils / filsPerDinar;
  double? get maxDiscountKd {
    final cap = maxDiscountFils;
    return cap == null ? null : cap / filsPerDinar;
  }

  /// Still running at [now] (the list route already filters, this guards a
  /// page left open past the end).
  bool isLiveAt(DateTime now) => endsAt == null || endsAt!.isAfter(now);

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    triggerType,
    minSubtotalFils,
    minQuantity,
    rewardType,
    percent,
    maxDiscountFils,
    amountFils,
    freeQuantity,
    stackable,
    endsAt,
  ];
}
