import 'package:equatable/equatable.dart';

import 'cart_applied_offer_entity.dart';
import 'cart_coupon_entity.dart';
import 'cart_line_entity.dart';
import 'cart_line_ref.dart';
import 'cart_loyalty_entity.dart';
import 'cart_offer_line_entity.dart';
import 'cart_offer_progress_entity.dart';
import 'cart_totals_entity.dart';
import 'catalog_product_entity.dart';

/// How the cart will be fulfilled (`fulfillmentMode`).
/// `fulfillmentMode` on the cart, a delivery selection and an order — one
/// decoder for all three ([fromWire]), so a new mode is one case here.
enum FulfillmentMode {
  delivery('delivery'),
  pickup('pickup'),
  other('');

  const FulfillmentMode(this.wireValue);

  final String wireValue;

  /// Unknown or missing values become [other] rather than a silent default.
  static FulfillmentMode fromWire(String? value) => switch (value) {
    'delivery' => delivery,
    'pickup' => pickup,
    _ => other,
  };
}

/// Why the cart cannot go to checkout yet, first reason wins.
enum CartCheckoutBlock {
  empty,
  lineIssue,
  belowMinOrder,
  branchClosed,
  noCapacity,
}

/// The server cart as every `/v1/cart*` route returns it. Shared by cart,
/// checkout and orders (reorder), so it lives in `core/domain`.
///
/// Prices, discounts, delivery fee and eligibility all come from the server;
/// the app never recomputes them. The offline-first mirror (`features/cart`)
/// only projects pending quantity changes on top (see `CartLineEntity.key`).
class CartEntity extends Equatable {
  const CartEntity({
    this.cartToken = '',
    this.itemCount = 0,
    this.fulfillmentMode = FulfillmentMode.delivery,
    this.lines = const <CartLineEntity>[],
    this.offerLines = const <CartOfferLineEntity>[],
    this.appliedOffers = const <CartAppliedOfferEntity>[],
    this.offerProgress = const <CartOfferProgressEntity>[],
    this.coupon,
    this.loyalty = const CartLoyaltyEntity(),
    this.expressOffered = false,
    this.expressSelected = false,
    this.expressEtaMinutes,
    this.expressSurchargeOfferedFils = 0,
    this.branchOpen = true,
    this.capacityAvailable = true,
    this.totals = const CartTotalsEntity(),
  });

  static const CartEntity empty = CartEntity();

  /// Guest cart identity; the app stores it and sends it while signed out.
  final String cartToken;

  /// Sum of paid line quantities.
  final int itemCount;
  final FulfillmentMode fulfillmentMode;
  final List<CartLineEntity> lines;
  final List<CartOfferLineEntity> offerLines;
  final List<CartAppliedOfferEntity> appliedOffers;
  final List<CartOfferProgressEntity> offerProgress;
  final CartCouponEntity? coupon;
  final CartLoyaltyEntity loyalty;
  final bool expressOffered;
  final bool expressSelected;
  final int? expressEtaMinutes;
  final int expressSurchargeOfferedFils;
  final bool branchOpen;
  final bool capacityAvailable;
  final CartTotalsEntity totals;

  bool get isEmpty => lines.isEmpty && offerLines.isEmpty;
  bool get isNotEmpty => !isEmpty;
  bool get hasBlockingIssue => lines.any((line) => line.blocksCheckout);
  bool get isPickup => fulfillmentMode == FulfillmentMode.pickup;
  double get expressSurchargeOfferedKd =>
      expressSurchargeOfferedFils / CatalogProductEntity.filsPerDinar;

  /// `null` when checkout may proceed.
  CartCheckoutBlock? get checkoutBlock {
    if (lines.isEmpty) return CartCheckoutBlock.empty;
    if (hasBlockingIssue) return CartCheckoutBlock.lineIssue;
    if (!totals.meetsMinOrder) return CartCheckoutBlock.belowMinOrder;
    if (!branchOpen) return CartCheckoutBlock.branchClosed;
    if (!capacityAvailable) return CartCheckoutBlock.noCapacity;
    return null;
  }

  bool get canCheckout => checkoutBlock == null;

  /// The line [ref] points at, compared on its fields so no `CartLineRef`
  /// is allocated per line (every visible tile calls this on every emission).
  CartLineEntity? lineFor(CartLineRef ref) {
    for (final line in lines) {
      if (line.product.id == ref.productId && line.variantId == ref.variantId) {
        return line;
      }
    }
    return null;
  }

  /// Product id → pieces, computed once per cart for the tiles.
  Map<String, int> get quantityByProduct {
    final map = <String, int>{};
    for (final line in lines) {
      map[line.product.id] = (map[line.product.id] ?? 0) + line.quantity;
    }
    return map;
  }

  CartEntity copyWith({
    String? cartToken,
    int? itemCount,
    List<CartLineEntity>? lines,
    CartTotalsEntity? totals,
  }) => CartEntity(
    cartToken: cartToken ?? this.cartToken,
    itemCount: itemCount ?? this.itemCount,
    fulfillmentMode: fulfillmentMode,
    lines: lines ?? this.lines,
    offerLines: offerLines,
    appliedOffers: appliedOffers,
    offerProgress: offerProgress,
    coupon: coupon,
    loyalty: loyalty,
    expressOffered: expressOffered,
    expressSelected: expressSelected,
    expressEtaMinutes: expressEtaMinutes,
    expressSurchargeOfferedFils: expressSurchargeOfferedFils,
    branchOpen: branchOpen,
    capacityAvailable: capacityAvailable,
    totals: totals ?? this.totals,
  );

  @override
  List<Object?> get props => [
    cartToken,
    itemCount,
    fulfillmentMode,
    lines,
    offerLines,
    appliedOffers,
    offerProgress,
    coupon,
    loyalty,
    expressOffered,
    expressSelected,
    expressEtaMinutes,
    expressSurchargeOfferedFils,
    branchOpen,
    capacityAvailable,
    totals,
  ];
}
