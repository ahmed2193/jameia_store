import '../../../../core/data/models/order_model.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/orders_page_model.dart';

/// The jm3eia customer order routes plus product reviews. `results` only
/// (the envelope is unwrapped by `DioConsumer`); throws `AppException`.
///
/// Reference: https://docs.jm3eia.store/developers/ (Orders, Reviews).
abstract class OrdersRemoteDataSource {
  /// `GET /v1/orders?page&limit` (limit 1..100).
  Future<OrdersPageModel> getOrders({required int page, required int limit});

  /// `GET /v1/orders/{orderId}`.
  Future<OrderModel> getOrder(String orderId);

  /// `POST /v1/orders/{orderId}/cancel { reason, note? }` → the order.
  Future<OrderModel> cancelOrder(String orderId, Map<String, dynamic> body);

  /// `POST /v1/reviews { productId, orderId, rating, title?, body? }`.
  Future<void> submitReview(Map<String, dynamic> body);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  const OrdersRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String _listRoute = 'orders';
  static const String _detailRoute = 'orders/{id}';

  @override
  Future<OrdersPageModel> getOrders({
    required int page,
    required int limit,
  }) async {
    final results = await _api.get(
      EndPoints.orders,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    return OrdersPageModel.fromJson(
      ApiPayload.asMap(results, _listRoute),
      requestedPage: page,
    );
  }

  @override
  Future<OrderModel> getOrder(String orderId) async => OrderModel.fromJson(
    ApiPayload.asMap(await _api.get(EndPoints.order(orderId)), _detailRoute),
  );

  @override
  Future<OrderModel> cancelOrder(
    String orderId,
    Map<String, dynamic> body,
  ) async => OrderModel.fromJson(
    ApiPayload.asMap(
      await _api.post(EndPoints.orderCancel(orderId), body: body),
      _detailRoute,
    ),
  );

  @override
  Future<void> submitReview(Map<String, dynamic> body) =>
      _api.post(EndPoints.reviews, body: body);
}
