import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/error/exceptions.dart';

/// `GET /v1/cart` → `lines[]`: one paid line; the embedded product is the
/// catalogue card (`ProductModel`).
class CartLineModel {
  const CartLineModel({
    required this.key,
    required this.product,
    this.quantity = 0,
    this.maxQuantity = 0,
    this.unitPrice = 0,
    this.compareAt,
    this.lineTotal = 0,
    this.variantId,
    this.variantName,
    this.issue,
  });

  static const String keyKey = 'key';
  static const String quantityKey = 'quantity';
  static const String maxQuantityKey = 'maxQuantity';
  static const String unitPriceKey = 'unitPrice';
  static const String compareAtKey = 'compareAt';
  static const String lineTotalKey = 'lineTotal';
  static const String variantIdKey = 'variantId';
  static const String variantNameKey = 'variantName';
  static const String productKey = 'product';
  static const String issueKey = 'issue';

  /// Throws [ParsingException] without a `key` or a readable product.
  factory CartLineModel.fromJson(Map<String, dynamic> json) {
    final key = JsonRead.string(json[keyKey]);
    if (key == null) throw const ParsingException('cart line: key missing');
    final product = JsonRead.object(json[productKey]);
    if (product == null) {
      throw const ParsingException('cart line: product missing');
    }
    return CartLineModel(
      key: key,
      product: ProductModel.fromJson(product),
      quantity: JsonRead.integer(json[quantityKey]) ?? 0,
      maxQuantity: JsonRead.integer(json[maxQuantityKey]) ?? 0,
      unitPrice: JsonRead.integer(json[unitPriceKey]) ?? 0,
      compareAt: JsonRead.integer(json[compareAtKey]),
      lineTotal: JsonRead.integer(json[lineTotalKey]) ?? 0,
      variantId: JsonRead.string(json[variantIdKey]),
      variantName: JsonRead.string(json[variantNameKey]),
      issue: JsonRead.string(json[issueKey]),
    );
  }

  final String key;
  final ProductModel product;
  final int quantity;
  final int maxQuantity;
  final int unitPrice;
  final int? compareAt;
  final int lineTotal;
  final String? variantId;
  final String? variantName;

  /// `null` | `out_of_stock` | `quantity_reduced` | `unavailable` (wire).
  final String? issue;

  Map<String, dynamic> toJson() => <String, dynamic>{
    keyKey: key,
    productKey: product.toJson(),
    quantityKey: quantity,
    maxQuantityKey: maxQuantity,
    unitPriceKey: unitPrice,
    if (compareAt != null) compareAtKey: compareAt,
    lineTotalKey: lineTotal,
    if (variantId != null) variantIdKey: variantId,
    if (variantName != null) variantNameKey: variantName,
    if (issue != null) issueKey: issue,
  };
}
