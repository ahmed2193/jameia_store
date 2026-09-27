import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_offer_progress_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import 'checkout_unlock.dart';

/// Why delivery is free, when it is.
enum FreeDeliveryReason {
  none,

  /// An applied free-delivery offer ([CheckoutOfferHints.appliedFreeDeliveryName]).
  offer,

  /// The customer's Pro membership.
  pro,
}

/// What the checkout may say about offers, decided once from the cart and
/// the store's offer list (`GET /v1/offers`): the nearest reward to unlock,
/// the gap to free delivery and why delivery is free.
///
/// A progress row counts only when it is honest to advertise: a subtotal
/// target still ahead, its offer known from the list (so its terms are
/// known), combinable with others (a non-stackable one may not add to what
/// the basket already gets) and running at the serving branch.
class CheckoutOfferHints extends Equatable {
  const CheckoutOfferHints({
    this.nearestUnlock,
    this.freeDeliveryGapFils,
    this.freeDeliveryReason = FreeDeliveryReason.none,
    this.appliedFreeDeliveryName = '',
  });

  static const CheckoutOfferHints none = CheckoutOfferHints();

  /// [branchId]: the serving branch (`selection.branchId`); [pickup]: the
  /// checkout is in pickup mode; [proFreeDelivery]: the store's Pro perk AND
  /// the customer's membership (`rules.proFreeDelivery && customer.isPro`).
  factory CheckoutOfferHints.of({
    required CartEntity cart,
    required List<OfferEntity> offers,
    required String? branchId,
    required bool pickup,
    required bool proFreeDelivery,
  }) {
    final (nearest, gap) = _progress(
      cart: cart,
      offers: offers,
      branchId: branchId,
      pickup: pickup,
    );
    var reason = FreeDeliveryReason.none;
    var appliedName = '';
    for (final applied in cart.appliedOffers) {
      if (applied.reward.type == OfferRewardType.freeDelivery) {
        reason = FreeDeliveryReason.offer;
        appliedName = applied.name;
        break;
      }
    }
    if (reason == FreeDeliveryReason.none &&
        cart.totals.deliveryIsFree &&
        proFreeDelivery) {
      reason = FreeDeliveryReason.pro;
    }
    return CheckoutOfferHints(
      nearestUnlock: nearest,
      freeDeliveryGapFils: gap,
      freeDeliveryReason: reason,
      appliedFreeDeliveryName: appliedName,
    );
  }

  /// [CheckoutOfferHints.nearestUnlock] alone: it does not depend on why
  /// delivery is free, so a caller that needs only the unlock passes no Pro
  /// facts.
  static CheckoutUnlock? nearestUnlockOf({
    required CartEntity cart,
    required List<OfferEntity> offers,
    required String? branchId,
    required bool pickup,
  }) => _progress(
    cart: cart,
    offers: offers,
    branchId: branchId,
    pickup: pickup,
  ).$1;

  /// Whether a free-delivery reward is still worth advertising: the order
  /// is delivered and delivery is not free already. The one rule the hints
  /// and the "Coupons & offers" goals share.
  static bool wantsFreeDelivery(CartEntity cart, {required bool pickup}) =>
      !pickup && !cart.totals.deliveryIsFree;

  /// The nearest eligible unlock and the nearest free-delivery gap.
  static (CheckoutUnlock?, int?) _progress({
    required CartEntity cart,
    required List<OfferEntity> offers,
    required String? branchId,
    required bool pickup,
  }) {
    final wantsFree = wantsFreeDelivery(cart, pickup: pickup);
    final byId = <String, OfferEntity>{
      for (final offer in offers) offer.id: offer,
    };
    CheckoutUnlock? nearest;
    int? gap;
    for (final progress in cart.offerProgress) {
      if (progress.kind != OfferProgressKind.subtotal ||
          progress.remainingValue <= 0) {
        continue;
      }
      final offer = byId[progress.offerId];
      if (offer == null || !offer.stackable || !offer.availableAt(branchId)) {
        continue;
      }
      final remaining = progress.remainingValue;
      if (offer.rewardType == OfferRewardType.freeDelivery) {
        if (!wantsFree) continue;
        if (gap == null || remaining < gap) gap = remaining;
      }
      if (nearest == null || remaining < nearest.remainingFils) {
        nearest = CheckoutUnlock(
          offerId: offer.id,
          remainingFils: remaining,
          rewardType: offer.rewardType,
          percent: offer.percent,
          amountFils: offer.amountFils,
          maxDiscountFils: offer.maxDiscountFils,
        );
      }
    }
    return (nearest, gap);
  }

  /// The eligible reward the basket is closest to (free delivery skipped
  /// while delivery is already free or the order is picked up).
  final CheckoutUnlock? nearestUnlock;

  /// What the subtotal is short of the nearest eligible free-delivery
  /// offer; `null` when delivery is free, for pickup, or without one.
  final int? freeDeliveryGapFils;

  /// [freeDeliveryGapFils] in dinar.
  double? get freeDeliveryGapKd {
    final gap = freeDeliveryGapFils;
    return gap == null ? null : gap / OfferEntity.filsPerDinar;
  }

  final FreeDeliveryReason freeDeliveryReason;

  /// The applied free-delivery offer's name (server-localized).
  final String appliedFreeDeliveryName;

  @override
  List<Object?> get props => [
    nearestUnlock,
    freeDeliveryGapFils,
    freeDeliveryReason,
    appliedFreeDeliveryName,
  ];
}
