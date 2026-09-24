import 'localized_text_model.dart';
import 'json_read.dart';
import '../../error/exceptions.dart';

/// `lines[]` of an order.
class OrderLineModel {
  const OrderLineModel({
    required this.key,
    required this.productId,
    this.name = LocalizedTextModel.empty,
    this.image = '',
    this.productType = '',
    this.variantId,
    this.variantName = LocalizedTextModel.empty,
    this.sku,
    this.quantity = 0,
    this.unitPrice = 0,
    this.lineTotal = 0,
  });

  static const String keyKey = 'key';
  static const String productKey = 'product';
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String imageKey = 'image';
  static const String typeKey = 'type';
  static const String variantKey = 'variant';
  static const String skuKey = 'sku';
  static const String quantityKey = 'quantity';
  static const String unitPriceKey = 'unitPrice';
  static const String lineTotalKey = 'lineTotal';

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    final key = JsonRead.string(json[keyKey]);
    final product = JsonRead.object(json[productKey]);
    final productId = product == null ? null : JsonRead.string(product[idKey]);
    if (key == null || productId == null) {
      throw const ParsingException('order line: identity missing');
    }
    final variant = JsonRead.object(json[variantKey]);
    return OrderLineModel(
      key: key,
      productId: productId,
      name: LocalizedTextModel.parse(product![nameKey]),
      image: JsonRead.string(product[imageKey]) ?? '',
      productType: JsonRead.string(product[typeKey]) ?? '',
      variantId: variant == null ? null : JsonRead.string(variant[idKey]),
      variantName: variant == null
          ? LocalizedTextModel.empty
          : LocalizedTextModel.parse(variant[nameKey]),
      sku: variant == null ? null : JsonRead.string(variant[skuKey]),
      quantity: JsonRead.integer(json[quantityKey]) ?? 0,
      unitPrice: JsonRead.integer(json[unitPriceKey]) ?? 0,
      lineTotal: JsonRead.integer(json[lineTotalKey]) ?? 0,
    );
  }

  final String key;
  final String productId;
  final LocalizedTextModel name;
  final String image;
  final String productType;
  final String? variantId;
  final LocalizedTextModel variantName;
  final String? sku;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
}

/// `offerLines[]` of an order.
class OrderOfferLineModel {
  const OrderOfferLineModel({
    required this.productId,
    required this.offerId,
    this.name = LocalizedTextModel.empty,
    this.image = '',
    this.offerName = LocalizedTextModel.empty,
    this.quantity = 0,
  });

  static const String productKey = 'product';
  static const String offerKey = 'offer';
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String imageKey = 'image';
  static const String quantityKey = 'quantity';

  factory OrderOfferLineModel.fromJson(Map<String, dynamic> json) {
    final product = JsonRead.object(json[productKey]);
    final offer = JsonRead.object(json[offerKey]);
    final productId = product == null ? null : JsonRead.string(product[idKey]);
    final offerId = offer == null ? null : JsonRead.string(offer[idKey]);
    if (productId == null || offerId == null) {
      throw const ParsingException('order offer line: identity missing');
    }
    return OrderOfferLineModel(
      productId: productId,
      offerId: offerId,
      name: LocalizedTextModel.parse(product![nameKey]),
      image: JsonRead.string(product[imageKey]) ?? '',
      offerName: LocalizedTextModel.parse(offer![nameKey]),
      quantity: JsonRead.integer(json[quantityKey]) ?? 0,
    );
  }

  final String productId;
  final String offerId;
  final LocalizedTextModel name;
  final String image;
  final LocalizedTextModel offerName;
  final int quantity;
}

/// `appliedOffers[]` of an order.
class OrderAppliedOfferModel {
  const OrderAppliedOfferModel({
    required this.id,
    this.name = LocalizedTextModel.empty,
    this.rewardType = '',
    this.discount = 0,
  });

  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String rewardTypeKey = 'rewardType';
  static const String discountKey = 'discount';

  factory OrderAppliedOfferModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('applied offer: id missing');
    return OrderAppliedOfferModel(
      id: id,
      name: LocalizedTextModel.parse(json[nameKey]),
      rewardType: JsonRead.string(json[rewardTypeKey]) ?? '',
      discount: JsonRead.integer(json[discountKey]) ?? 0,
    );
  }

  final String id;
  final LocalizedTextModel name;
  final String rewardType;
  final int discount;
}
