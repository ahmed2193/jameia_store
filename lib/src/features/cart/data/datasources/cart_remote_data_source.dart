import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/cart_model.dart';

/// The jm3eia cart routes. Every call answers with the whole cart
/// (`results`, unwrapped by `DioConsumer`). While signed out the guest
/// `X-Cart-Token` header goes out automatically (`AppHeadersInterceptor`);
/// signed in, the Bearer names the customer's cart. Throws `AppException`
/// only.
///
/// Reference: https://docs.jm3eia.store/developers/ (Cart).
abstract class CartRemoteDataSource {
  /// `GET /v1/cart`.
  Future<CartModel> getCart();

  /// `POST /v1/cart/items { items: [{ productId, variantId?, quantity }] }`
  /// — adds to existing lines, at most 50 rows.
  Future<CartModel> addItems(List<Map<String, dynamic>> items);

  /// `PATCH /v1/cart/items/{key} { quantity }` — absolute; `0` removes.
  Future<CartModel> setLineQuantity(String key, int quantity);

  /// `DELETE /v1/cart/items/{key}`.
  Future<CartModel> removeLine(String key);

  /// `DELETE /v1/cart` — empties the cart.
  Future<CartModel> clear();

  /// `POST /v1/cart/coupon { code }`.
  Future<CartModel> applyCoupon(String code);

  /// `DELETE /v1/cart/coupon`.
  Future<CartModel> removeCoupon();

  /// `POST /v1/cart/loyalty { points }`.
  Future<CartModel> applyLoyalty(int points);

  /// `DELETE /v1/cart/loyalty`.
  Future<CartModel> removeLoyalty();

  /// `POST /v1/cart/express { enabled }`.
  Future<CartModel> setExpress({required bool enabled});
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  const CartRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String _route = 'cart';
  static const String itemsField = 'items';
  static const String quantityField = 'quantity';
  static const String codeField = 'code';
  static const String pointsField = 'points';
  static const String enabledField = 'enabled';

  CartModel _cart(Object? results) =>
      CartModel.fromJson(ApiPayload.asMap(results, _route));

  @override
  Future<CartModel> getCart() async => _cart(await _api.get(EndPoints.cart));

  @override
  Future<CartModel> addItems(List<Map<String, dynamic>> items) async => _cart(
    await _api.post(
      EndPoints.cartItems,
      body: <String, dynamic>{itemsField: items},
    ),
  );

  @override
  Future<CartModel> setLineQuantity(String key, int quantity) async => _cart(
    await _api.patch(
      EndPoints.cartItem(key),
      body: <String, dynamic>{quantityField: quantity},
    ),
  );

  @override
  Future<CartModel> removeLine(String key) async =>
      _cart(await _api.delete(EndPoints.cartItem(key)));

  @override
  Future<CartModel> clear() async => _cart(await _api.delete(EndPoints.cart));

  @override
  Future<CartModel> applyCoupon(String code) async => _cart(
    await _api.post(
      EndPoints.cartCoupon,
      body: <String, dynamic>{codeField: code},
    ),
  );

  @override
  Future<CartModel> removeCoupon() async =>
      _cart(await _api.delete(EndPoints.cartCoupon));

  @override
  Future<CartModel> applyLoyalty(int points) async => _cart(
    await _api.post(
      EndPoints.cartLoyalty,
      body: <String, dynamic>{pointsField: points},
    ),
  );

  @override
  Future<CartModel> removeLoyalty() async =>
      _cart(await _api.delete(EndPoints.cartLoyalty));

  @override
  Future<CartModel> setExpress({required bool enabled}) async => _cart(
    await _api.post(
      EndPoints.cartExpress,
      body: <String, dynamic>{enabledField: enabled},
    ),
  );
}
