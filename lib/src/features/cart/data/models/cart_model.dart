import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'cart_line_model.dart';
import 'cart_offer_models.dart';
import 'cart_totals_model.dart';

export 'cart_line_model.dart';
export 'cart_offer_models.dart';
export 'cart_totals_model.dart';

/// The cart every `/v1/cart*` route returns (`results`). Every nested row is
/// tolerant: a malformed line is logged and skipped, a missing scalar takes
/// its default; only a cart without `cartToken` is unreadable.
///
/// [toJson] writes the same wire shape back for the on-device mirror, so a
/// cold start restores through the same [fromJson].
///
/// Reference: https://api.jm3eia.store/docs (Cart → `GET /v1/cart`).
class CartModel {
  const CartModel({
    required this.cartToken,
    this.itemCount = 0,
    this.fulfillmentMode = deliveryMode,
    this.lines = const <CartLineModel>[],
    this.offerLines = const <CartOfferLineModel>[],
    this.appliedOffers = const <CartAppliedOfferModel>[],
    this.offerProgress = const <CartOfferProgressModel>[],
    this.coupon,
    this.loyalty = const CartLoyaltyModel(),
    this.expressOffered = false,
    this.expressSelected = false,
    this.expressEtaMinutes,
    this.expressSurchargeOffered = 0,
    this.branchOpen = true,
    this.capacityAvailable = true,
    this.totals = const CartTotalsModel(),
  });

  static const String cartTokenKey = 'cartToken';
  static const String itemCountKey = 'itemCount';
  static const String fulfillmentModeKey = 'fulfillmentMode';
  static const String linesKey = 'lines';
  static const String offerLinesKey = 'offerLines';
  static const String appliedOffersKey = 'appliedOffers';
  static const String offerProgressKey = 'offerProgress';
  static const String couponKey = 'coupon';
  static const String loyaltyKey = 'loyalty';
  static const String expressOfferedKey = 'expressOffered';
  static const String expressSelectedKey = 'expressSelected';
  static const String expressEtaMinutesKey = 'expressEtaMinutes';
  static const String expressSurchargeOfferedKey = 'expressSurchargeOffered';
  static const String branchOpenKey = 'branchOpen';
  static const String capacityAvailableKey = 'capacityAvailable';
  static const String totalsKey = 'totals';
  static const String deliveryMode = 'delivery';
  static const String _logName = 'CartModel';

  /// Throws [ParsingException] without a `cartToken`.
  factory CartModel.fromJson(Map<String, dynamic> json) {
    final cartToken = JsonRead.string(json[cartTokenKey]);
    if (cartToken == null) {
      throw const ParsingException('cart: cartToken missing');
    }
    final coupon = JsonRead.object(json[couponKey]);
    final loyalty = JsonRead.object(json[loyaltyKey]);
    final totals = JsonRead.object(json[totalsKey]);
    return CartModel(
      cartToken: cartToken,
      itemCount: JsonRead.integer(json[itemCountKey]) ?? 0,
      fulfillmentMode:
          JsonRead.string(json[fulfillmentModeKey]) ?? deliveryMode,
      lines: JsonRead.rows(
        json[linesKey],
        CartLineModel.fromJson,
        logName: _logName,
      ),
      offerLines: JsonRead.rows(
        json[offerLinesKey],
        CartOfferLineModel.fromJson,
        logName: _logName,
      ),
      appliedOffers: JsonRead.rows(
        json[appliedOffersKey],
        CartAppliedOfferModel.fromJson,
        logName: _logName,
      ),
      offerProgress: JsonRead.rows(
        json[offerProgressKey],
        CartOfferProgressModel.fromJson,
        logName: _logName,
      ),
      coupon: coupon == null ? null : CartCouponModel.tryParse(coupon),
      loyalty: loyalty == null
          ? const CartLoyaltyModel()
          : CartLoyaltyModel.fromJson(loyalty),
      expressOffered: JsonRead.flag(json[expressOfferedKey]),
      expressSelected: JsonRead.flag(json[expressSelectedKey]),
      expressEtaMinutes: JsonRead.integer(json[expressEtaMinutesKey]),
      expressSurchargeOffered:
          JsonRead.integer(json[expressSurchargeOfferedKey]) ?? 0,
      branchOpen: JsonRead.flag(json[branchOpenKey], fallback: true),
      capacityAvailable: JsonRead.flag(
        json[capacityAvailableKey],
        fallback: true,
      ),
      totals: totals == null
          ? const CartTotalsModel()
          : CartTotalsModel.fromJson(totals),
    );
  }

  final String cartToken;
  final int itemCount;

  /// `delivery` | `pickup` (wire value).
  final String fulfillmentMode;
  final List<CartLineModel> lines;
  final List<CartOfferLineModel> offerLines;
  final List<CartAppliedOfferModel> appliedOffers;
  final List<CartOfferProgressModel> offerProgress;
  final CartCouponModel? coupon;
  final CartLoyaltyModel loyalty;
  final bool expressOffered;
  final bool expressSelected;
  final int? expressEtaMinutes;
  final int expressSurchargeOffered;
  final bool branchOpen;
  final bool capacityAvailable;
  final CartTotalsModel totals;

  Map<String, dynamic> toJson() => <String, dynamic>{
    cartTokenKey: cartToken,
    itemCountKey: itemCount,
    fulfillmentModeKey: fulfillmentMode,
    linesKey: [for (final line in lines) line.toJson()],
    offerLinesKey: [for (final line in offerLines) line.toJson()],
    appliedOffersKey: [for (final offer in appliedOffers) offer.toJson()],
    offerProgressKey: [for (final row in offerProgress) row.toJson()],
    if (coupon != null) couponKey: coupon!.toJson(),
    loyaltyKey: loyalty.toJson(),
    expressOfferedKey: expressOffered,
    expressSelectedKey: expressSelected,
    if (expressEtaMinutes != null) expressEtaMinutesKey: expressEtaMinutes,
    expressSurchargeOfferedKey: expressSurchargeOffered,
    branchOpenKey: branchOpen,
    capacityAvailableKey: capacityAvailable,
    totalsKey: totals.toJson(),
  };
}
