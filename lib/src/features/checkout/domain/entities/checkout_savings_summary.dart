import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';

/// What the "Coupons & offers" row says at its end.
enum CheckoutSavingsKind {
  /// Nothing applied: "Add a code".
  none,

  /// A coupon that saves: "{code} · saved {amount}".
  code,

  /// A coupon the server kept but that saves nothing on this basket.
  codeNoSaving,

  /// Only offers: "Offers · saved {amount}".
  offers,

  /// A coupon and offers: "Saved {coupon + offers}".
  combined,
}

/// The coupons-and-offers figure, from the server's totals and the coupon's
/// code only (points have their own row, so they are not counted here).
class CheckoutSavingsSummary extends Equatable {
  const CheckoutSavingsSummary({
    this.kind = CheckoutSavingsKind.none,
    this.fils = 0,
    this.code = '',
  });

  factory CheckoutSavingsSummary.of(CartEntity cart) {
    final totals = cart.totals;
    final code = cart.coupon?.code;
    final offers = totals.offerDiscountFils;
    if (code != null) {
      if (offers > 0) {
        return CheckoutSavingsSummary(
          kind: CheckoutSavingsKind.combined,
          fils: totals.couponDiscountFils + offers,
          code: code,
        );
      }
      return totals.couponDiscountFils > 0
          ? CheckoutSavingsSummary(
              kind: CheckoutSavingsKind.code,
              fils: totals.couponDiscountFils,
              code: code,
            )
          : CheckoutSavingsSummary(
              kind: CheckoutSavingsKind.codeNoSaving,
              code: code,
            );
    }
    if (offers > 0) {
      return CheckoutSavingsSummary(
        kind: CheckoutSavingsKind.offers,
        fils: offers,
      );
    }
    return const CheckoutSavingsSummary();
  }

  final CheckoutSavingsKind kind;
  final int fils;

  /// The coupon's code; empty without one.
  final String code;

  double get kd => fils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [kind, fils, code];
}
