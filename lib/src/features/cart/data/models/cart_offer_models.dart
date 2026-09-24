import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/error/exceptions.dart';

/// `GET /v1/cart` → `offerLines[]`: a free product an offer added.
class CartOfferLineModel {
  const CartOfferLineModel({
    required this.key,
    required this.offerId,
    required this.product,
    this.offerName = '',
    this.quantity = 0,
  });

  static const String keyKey = 'key';
  static const String quantityKey = 'quantity';
  static const String offerIdKey = 'offerId';
  static const String offerNameKey = 'offerName';
  static const String productKey = 'product';

  factory CartOfferLineModel.fromJson(Map<String, dynamic> json) {
    final key = JsonRead.string(json[keyKey]);
    final offerId = JsonRead.string(json[offerIdKey]);
    final product = JsonRead.object(json[productKey]);
    if (key == null || offerId == null || product == null) {
      throw const ParsingException('cart offer line: identity missing');
    }
    return CartOfferLineModel(
      key: key,
      offerId: offerId,
      product: ProductModel.fromJson(product),
      offerName: JsonRead.string(json[offerNameKey]) ?? '',
      quantity: JsonRead.integer(json[quantityKey]) ?? 0,
    );
  }

  final String key;
  final String offerId;
  final String offerName;
  final int quantity;
  final ProductModel product;

  Map<String, dynamic> toJson() => <String, dynamic>{
    keyKey: key,
    offerIdKey: offerId,
    offerNameKey: offerName,
    quantityKey: quantity,
    productKey: product.toJson(),
  };
}

/// `appliedOffers[].reward` / `offerProgress[].reward`: a tagged union on
/// `type` (`free_delivery` | `percentage_discount` | `fixed_discount` |
/// `free_product`), kept flat here.
class OfferRewardModel {
  const OfferRewardModel({
    this.type = '',
    this.percent = 0,
    this.maxDiscount,
    this.amount = 0,
    this.productId,
    this.quantity = 0,
  });

  static const String typeKey = 'type';
  static const String percentKey = 'percent';
  static const String maxDiscountKey = 'maxDiscount';
  static const String amountKey = 'amount';
  static const String productIdKey = 'productId';
  static const String quantityKey = 'quantity';

  factory OfferRewardModel.fromJson(Map<String, dynamic> json) =>
      OfferRewardModel(
        type: JsonRead.string(json[typeKey]) ?? '',
        percent: JsonRead.integer(json[percentKey]) ?? 0,
        maxDiscount: JsonRead.integer(json[maxDiscountKey]),
        amount: JsonRead.integer(json[amountKey]) ?? 0,
        productId: JsonRead.string(json[productIdKey]),
        quantity: JsonRead.integer(json[quantityKey]) ?? 0,
      );

  final String type;
  final int percent;
  final int? maxDiscount;
  final int amount;
  final String? productId;
  final int quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    typeKey: type,
    percentKey: percent,
    if (maxDiscount != null) maxDiscountKey: maxDiscount,
    amountKey: amount,
    if (productId != null) productIdKey: productId,
    quantityKey: quantity,
  };
}

/// `appliedOffers[]`.
class CartAppliedOfferModel {
  const CartAppliedOfferModel({
    required this.offerId,
    this.name = '',
    this.rewardType = '',
    this.discount = 0,
    this.reward = const OfferRewardModel(),
  });

  static const String offerIdKey = 'offerId';
  static const String nameKey = 'name';
  static const String rewardTypeKey = 'rewardType';
  static const String discountKey = 'discount';
  static const String rewardKey = 'reward';

  factory CartAppliedOfferModel.fromJson(Map<String, dynamic> json) {
    final offerId = JsonRead.string(json[offerIdKey]);
    if (offerId == null) {
      throw const ParsingException('applied offer: offerId missing');
    }
    final reward = JsonRead.object(json[rewardKey]);
    return CartAppliedOfferModel(
      offerId: offerId,
      name: JsonRead.string(json[nameKey]) ?? '',
      rewardType: JsonRead.string(json[rewardTypeKey]) ?? '',
      discount: JsonRead.integer(json[discountKey]) ?? 0,
      reward: reward == null
          ? const OfferRewardModel()
          : OfferRewardModel.fromJson(reward),
    );
  }

  final String offerId;
  final String name;
  final String rewardType;
  final int discount;
  final OfferRewardModel reward;

  Map<String, dynamic> toJson() => <String, dynamic>{
    offerIdKey: offerId,
    nameKey: name,
    rewardTypeKey: rewardType,
    discountKey: discount,
    rewardKey: reward.toJson(),
  };
}

/// `offerProgress[]`: "add X more to unlock".
class CartOfferProgressModel {
  const CartOfferProgressModel({
    required this.offerId,
    this.name = '',
    this.kind = '',
    this.currentValue = 0,
    this.targetValue = 0,
    this.remainingValue = 0,
    this.contextId,
    this.contextName,
    this.reward = const OfferRewardModel(),
    this.rewardProduct,
  });

  static const String offerIdKey = 'offerId';
  static const String nameKey = 'name';
  static const String kindKey = 'kind';
  static const String currentValueKey = 'currentValue';
  static const String targetValueKey = 'targetValue';
  static const String remainingValueKey = 'remainingValue';
  static const String contextIdKey = 'contextId';
  static const String contextNameKey = 'contextName';
  static const String rewardKey = 'reward';
  static const String rewardProductKey = 'rewardProduct';

  factory CartOfferProgressModel.fromJson(Map<String, dynamic> json) {
    final offerId = JsonRead.string(json[offerIdKey]);
    if (offerId == null) {
      throw const ParsingException('offer progress: offerId missing');
    }
    final reward = JsonRead.object(json[rewardKey]);
    final rewardProduct = JsonRead.object(json[rewardProductKey]);
    return CartOfferProgressModel(
      offerId: offerId,
      name: JsonRead.string(json[nameKey]) ?? '',
      kind: JsonRead.string(json[kindKey]) ?? '',
      currentValue: JsonRead.integer(json[currentValueKey]) ?? 0,
      targetValue: JsonRead.integer(json[targetValueKey]) ?? 0,
      remainingValue: JsonRead.integer(json[remainingValueKey]) ?? 0,
      contextId: JsonRead.string(json[contextIdKey]),
      contextName: JsonRead.string(json[contextNameKey]),
      reward: reward == null
          ? const OfferRewardModel()
          : OfferRewardModel.fromJson(reward),
      rewardProduct: rewardProduct == null ? null : _tryProduct(rewardProduct),
    );
  }

  /// A reward product without an id / slug is dropped, not the whole row.
  static ProductModel? _tryProduct(Map<String, dynamic> json) {
    try {
      return ProductModel.fromJson(json);
    } on ParsingException {
      return null;
    }
  }

  final String offerId;
  final String name;

  /// `subtotal` | `item` | `category` (wire value).
  final String kind;
  final int currentValue;
  final int targetValue;
  final int remainingValue;
  final String? contextId;
  final String? contextName;
  final OfferRewardModel reward;
  final ProductModel? rewardProduct;

  Map<String, dynamic> toJson() => <String, dynamic>{
    offerIdKey: offerId,
    nameKey: name,
    kindKey: kind,
    currentValueKey: currentValue,
    targetValueKey: targetValue,
    remainingValueKey: remainingValue,
    if (contextId != null) contextIdKey: contextId,
    if (contextName != null) contextNameKey: contextName,
    rewardKey: reward.toJson(),
    if (rewardProduct != null) rewardProductKey: rewardProduct!.toJson(),
  };
}

/// `coupon` — `null` when none is applied.
class CartCouponModel {
  const CartCouponModel({required this.code, this.discount = 0});

  static const String codeKey = 'code';
  static const String discountKey = 'discount';

  /// `null` when the object carries no code (treated as "no coupon").
  static CartCouponModel? tryParse(Map<String, dynamic> json) {
    final code = JsonRead.string(json[codeKey]);
    if (code == null) return null;
    return CartCouponModel(
      code: code,
      discount: JsonRead.integer(json[discountKey]) ?? 0,
    );
  }

  final String code;
  final int discount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    codeKey: code,
    discountKey: discount,
  };
}

/// `loyalty`.
class CartLoyaltyModel {
  const CartLoyaltyModel({this.pointsApplied = 0, this.discount = 0});

  static const String pointsAppliedKey = 'pointsApplied';
  static const String discountKey = 'discount';

  factory CartLoyaltyModel.fromJson(Map<String, dynamic> json) =>
      CartLoyaltyModel(
        pointsApplied: JsonRead.integer(json[pointsAppliedKey]) ?? 0,
        discount: JsonRead.integer(json[discountKey]) ?? 0,
      );

  final int pointsApplied;
  final int discount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    pointsAppliedKey: pointsApplied,
    discountKey: discount,
  };
}
