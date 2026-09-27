import 'dart:developer';

import 'package:equatable/equatable.dart';

import 'cart_entity.dart';
import 'cart_line_entity.dart';
import 'cart_top_saving.dart';
import 'catalog_product_entity.dart';
import 'offer_reward_entity.dart';

/// Everything a basket saves, in fils — the one definition the cart bar and
/// the checkout (bar, receipt, hint) share, so the struck total means the
/// same thing on both screens.
///
/// - [itemSavingsFils]: Σ lines `(compareAt − unitPrice) × quantity`.
/// - [discountFils]: the server's discounts (coupon + points + offers).
/// - [waivedDeliveryFils]: the delivery fee free delivery waived, counted
///   only when the server did not already count it inside [discountFils]
///   and no fee is still charged (see [CartSavings.of]).
///
/// Pure arithmetic on server figures; nothing here re-prices the cart.
class CartSavings extends Equatable {
  const CartSavings({
    this.itemSavingsFils = 0,
    this.discountFils = 0,
    this.waivedDeliveryFils = 0,
    this.subtotalFils = 0,
    this.totalFils = 0,
    this.top,
  });

  /// Nothing saved.
  static const CartSavings none = CartSavings();

  /// The savings of [cart]. [quotedDeliveryFeeFils] is the fee the delivery
  /// selection quoted (`select-address` / `select-branch` → `deliveryFee`),
  /// the fallback for the waived fee when the cart carries no list price.
  ///
  /// Cached per cart instance and quoted fee: several selectors read it on
  /// every emission, and a cart snapshot never changes. Each fee keeps its
  /// own entry, so the cart tab (no fee) and the checkout (the quoted fee)
  /// reading the same snapshot do not evict each other.
  factory CartSavings.of(CartEntity cart, {int? quotedDeliveryFeeFils}) {
    final byFee = _cache[cart] ??= <int?, CartSavings>{};
    return byFee[quotedDeliveryFeeFils] ??= _compute(
      cart,
      quotedDeliveryFeeFils,
    );
  }

  static final Expando<Map<int?, CartSavings>> _cache =
      Expando<Map<int?, CartSavings>>('CartSavings');

  /// Carts whose money identity was already reported (debug only).
  static final Expando<bool> _reported = Expando<bool>('CartSavings.reported');

  static const String _logName = 'savings';

  final int itemSavingsFils;
  final int discountFils;
  final int waivedDeliveryFils;
  final int subtotalFils;
  final int totalFils;

  /// The line that saves the most (first one on a tie); `null` when no line
  /// is on sale.
  final CartTopSaving? top;

  int get totalSavingsFils =>
      itemSavingsFils + discountFils + waivedDeliveryFils;
  bool get hasSavings => totalSavingsFils > 0;

  /// The subtotal at the struck (list) prices.
  int get listSubtotalFils => subtotalFils + itemSavingsFils;

  /// THE struck total of the app: what the basket would cost without any of
  /// its savings; `null` when it saves nothing.
  ///
  /// The cart bar reads it without a quoted fee, the checkout bar with the
  /// fee its delivery selection quoted. They agree whenever the cart carries
  /// its list fee (`baseDeliveryFee`) or delivery is not free; only a free
  /// delivery with no list fee on the cart lets the checkout count the
  /// quoted fee as waived where the cart tab cannot know it.
  int? get struckTotalFils => hasSavings ? totalFils + totalSavingsFils : null;

  double get itemSavingsKd =>
      itemSavingsFils / CatalogProductEntity.filsPerDinar;
  double get waivedDeliveryKd =>
      waivedDeliveryFils / CatalogProductEntity.filsPerDinar;
  double get totalSavingsKd =>
      totalSavingsFils / CatalogProductEntity.filsPerDinar;
  double get listSubtotalKd =>
      listSubtotalFils / CatalogProductEntity.filsPerDinar;
  double? get struckTotalKd {
    final fils = struckTotalFils;
    return fils == null ? null : fils / CatalogProductEntity.filsPerDinar;
  }

  static CartSavings _compute(CartEntity cart, int? quotedDeliveryFeeFils) {
    assert(() {
      _checkIdentity(cart);
      return true;
    }());
    var items = 0;
    CartLineEntity? best;
    for (final line in cart.lines) {
      final saving = line.savingFils;
      items += saving;
      if (saving > 0 && (best == null || saving > best.savingFils)) {
        best = line;
      }
    }
    final totals = cart.totals;
    return CartSavings(
      itemSavingsFils: items,
      discountFils: totals.discountFils,
      waivedDeliveryFils: _waivedDelivery(cart, quotedDeliveryFeeFils),
      subtotalFils: totals.subtotalFils,
      totalFils: totals.totalFils,
      top: best == null
          ? null
          : CartTopSaving(
              ref: best.ref,
              imageUrl: best.product.image,
              quantity: best.quantity,
              savingFils: best.savingFils,
            ),
    );
  }

  /// The fee free delivery waived. Nothing when there is nothing to deliver
  /// (pickup, an empty basket) or delivery is not free
  /// ([CartTotalsEntity.deliveryIsFree]: a fee still charged waived nothing).
  ///
  /// An applied free-delivery offer that reports a `discount` names the
  /// waiver first — unless the server already counts that amount in
  /// `offerDiscount` (then adding it again would count it twice). Otherwise
  /// the cart's list fee, else the fee the selection quoted.
  static int _waivedDelivery(CartEntity cart, int? quotedDeliveryFeeFils) {
    final totals = cart.totals;
    if (cart.isPickup || cart.lines.isEmpty || !totals.deliveryIsFree) {
      return 0;
    }
    for (final offer in cart.appliedOffers) {
      if (offer.reward.type != OfferRewardType.freeDelivery ||
          offer.discountFils <= 0) {
        continue;
      }
      return totals.offerDiscountFils >= offer.discountFils
          ? 0
          : offer.discountFils;
    }
    if (totals.baseDeliveryFeeFils > 0) return totals.baseDeliveryFeeFils;
    final quoted = quotedDeliveryFeeFils ?? 0;
    return quoted > 0 ? quoted : 0;
  }

  /// Debug only: `total == max(0, subtotal − discount) + deliveryFee` is how
  /// the receipt adds up. A mismatch (reported once per cart snapshot under
  /// the `savings` log) means the server adds its figures another way —
  /// expected for a moment while local taps re-price the basket.
  static void _checkIdentity(CartEntity cart) {
    if (cart.lines.isEmpty || _reported[cart] == true) return;
    final totals = cart.totals;
    final net = totals.subtotalFils - totals.discountFils;
    final expected = (net < 0 ? 0 : net) + totals.deliveryFeeFils;
    if (expected == totals.totalFils) return;
    _reported[cart] = true;
    log(
      'total ${totals.totalFils} != max(0, subtotal ${totals.subtotalFils} '
      '- discount ${totals.discountFils}) + deliveryFee '
      '${totals.deliveryFeeFils} (express ${totals.expressSurchargeFils}, '
      'free ${totals.freeDelivery})',
      name: _logName,
    );
  }

  @override
  List<Object?> get props => [
    itemSavingsFils,
    discountFils,
    waivedDeliveryFils,
    subtotalFils,
    totalFils,
    top,
  ];
}
