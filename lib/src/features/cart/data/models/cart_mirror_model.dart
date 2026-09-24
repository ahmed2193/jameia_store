import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/error/exceptions.dart';
import 'cart_model.dart';

/// What the device keeps of the cart between launches: whose it is, the
/// last server cart as received, and the changes still owed to the server.
class CartMirrorModel {
  const CartMirrorModel({
    required this.ownerId,
    this.cart,
    this.pending = const <CartPendingChangeModel>[],
  });

  static const String ownerIdKey = 'ownerId';
  static const String cartKey = 'cart';
  static const String pendingKey = 'pending';
  static const String _logName = 'CartMirrorModel';

  /// Throws [ParsingException] without an owner.
  factory CartMirrorModel.fromJson(Map<String, dynamic> json) {
    final ownerId = JsonRead.string(json[ownerIdKey]);
    if (ownerId == null) {
      throw const ParsingException('cart mirror: ownerId missing');
    }
    final cart = JsonRead.object(json[cartKey]);
    return CartMirrorModel(
      ownerId: ownerId,
      cart: cart == null ? null : CartModel.fromJson(cart),
      pending: JsonRead.rows(
        json[pendingKey],
        CartPendingChangeModel.fromJson,
        logName: _logName,
      ),
    );
  }

  /// Customer id, or the guest marker while signed out.
  final String ownerId;
  final CartModel? cart;
  final List<CartPendingChangeModel> pending;

  Map<String, dynamic> toJson() => <String, dynamic>{
    ownerIdKey: ownerId,
    if (cart != null) cartKey: cart!.toJson(),
    pendingKey: [for (final change in pending) change.toJson()],
  };
}

/// One queued change (see `CartPendingChange`).
class CartPendingChangeModel {
  const CartPendingChangeModel({
    required this.productId,
    this.variantId,
    this.delta = 0,
    this.absolute,
    this.product,
  });

  static const String productIdKey = 'productId';
  static const String variantIdKey = 'variantId';
  static const String deltaKey = 'delta';
  static const String absoluteKey = 'absolute';
  static const String productKey = 'product';

  factory CartPendingChangeModel.fromJson(Map<String, dynamic> json) {
    final productId = JsonRead.string(json[productIdKey]);
    if (productId == null) {
      throw const ParsingException('pending change: productId missing');
    }
    final product = JsonRead.object(json[productKey]);
    return CartPendingChangeModel(
      productId: productId,
      variantId: JsonRead.string(json[variantIdKey]),
      delta: JsonRead.integer(json[deltaKey]) ?? 0,
      absolute: JsonRead.integer(json[absoluteKey]),
      product: product == null ? null : ProductModel.fromJson(product),
    );
  }

  final String productId;
  final String? variantId;
  final int delta;
  final int? absolute;
  final ProductModel? product;

  Map<String, dynamic> toJson() => <String, dynamic>{
    productIdKey: productId,
    if (variantId != null) variantIdKey: variantId,
    deltaKey: delta,
    if (absolute != null) absoluteKey: absolute,
    if (product != null) productKey: product!.toJson(),
  };
}
