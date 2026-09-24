import '../../../../core/data/models/order_model.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';

/// `POST /v1/orders` — turns the server cart into an order.
abstract class CheckoutRemoteDataSource {
  /// `POST /v1/orders { paymentMethod, notes?, deliverySlot? }` → Order.
  Future<OrderModel> placeOrder(Map<String, dynamic> body);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  const CheckoutRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String _route = 'orders';

  @override
  Future<OrderModel> placeOrder(Map<String, dynamic> body) async =>
      OrderModel.fromJson(
        ApiPayload.asMap(await _api.post(EndPoints.orders, body: body), _route),
      );
}
