import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_savings.dart';
import 'checkout_bar_fact.dart';
import 'checkout_block_reason.dart';
import 'checkout_offer_hints.dart';

/// What the line under the bar's total says: one [pinned] fact that stays
/// put (a price that is not quoted yet, or a reason the order cannot go), or
/// the positive facts that rotate — only the true ones.
class CheckoutBarFacts extends Equatable {
  const CheckoutBarFacts({
    this.pinned,
    this.rotating = const <CheckoutBarFact>[],
  });

  static const CheckoutBarFacts none = CheckoutBarFacts();

  /// Rules: an empty basket says nothing; an unquoted destination pins
  /// "choose an address"; a blocking [reason] is pinned alone — except
  /// `destination`, `slot` and `empty`, which the page handles on its own;
  /// otherwise, in order: every saving together (hidden while [updating],
  /// because it mixes local figures with the last server totals), the
  /// coupon's saving, the points' saving, free delivery (the receipt's own
  /// rule, `CartTotalsEntity.deliveryIsFree`: no fee still charged), the
  /// gap to free delivery.
  factory CheckoutBarFacts.of({
    required CartEntity cart,
    required CartSavings savings,
    required CheckoutOfferHints hints,
    required bool quoted,
    required bool updating,
    required CheckoutBlockReason? reason,
  }) {
    if (cart.lines.isEmpty) return none;
    if (!quoted) {
      return const CheckoutBarFacts(
        pinned: CheckoutBarFact(CheckoutBarFactKind.chooseDestination),
      );
    }
    if (reason != null &&
        reason != CheckoutBlockReason.destination &&
        reason != CheckoutBlockReason.slot &&
        reason != CheckoutBlockReason.empty) {
      return CheckoutBarFacts(
        pinned: CheckoutBarFact.blocked(
          reason,
          fils: reason == CheckoutBlockReason.minOrder
              ? cart.totals.shortfallFils
              : 0,
        ),
      );
    }
    final totals = cart.totals;
    final coupon = cart.coupon;
    final gap = hints.freeDeliveryGapFils;
    return CheckoutBarFacts(
      rotating: List<CheckoutBarFact>.unmodifiable(<CheckoutBarFact>[
        if (!updating && savings.totalSavingsFils > 0)
          CheckoutBarFact(
            CheckoutBarFactKind.totalSavings,
            fils: savings.totalSavingsFils,
          ),
        if (coupon != null && totals.couponDiscountFils > 0)
          CheckoutBarFact(
            CheckoutBarFactKind.couponSaved,
            fils: totals.couponDiscountFils,
            code: coupon.code,
          ),
        if (totals.loyaltyDiscountFils > 0)
          CheckoutBarFact(
            CheckoutBarFactKind.pointsSaved,
            fils: totals.loyaltyDiscountFils,
          ),
        if (!cart.isPickup && totals.deliveryIsFree)
          const CheckoutBarFact(CheckoutBarFactKind.freeDelivery),
        if (gap != null && gap > 0)
          CheckoutBarFact(CheckoutBarFactKind.freeDeliveryGap, fils: gap),
      ]),
    );
  }

  /// A fact that stays put (no rotation); `null` when the facts rotate.
  final CheckoutBarFact? pinned;
  final List<CheckoutBarFact> rotating;

  bool get isEmpty => pinned == null && rotating.isEmpty;

  @override
  List<Object?> get props => [pinned, rotating];
}
