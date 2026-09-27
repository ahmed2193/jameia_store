import '../../../../core/data/models/order_model.dart';
import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/orders_page_model.dart';

/// The Hero customer order routes plus product reviews. `results` only
/// (the envelope is unwrapped by `DioConsumer`); throws `AppException`. An
/// order read (or a cancel) comes back with its raw `results` too, which the
/// repository keeps on the device.
///
/// Reference: https://docs.jm3eia.store/developers/ (Orders, Reviews).
abstract class OrdersRemoteDataSource {
  /// `GET /v1/orders?page&limit` (limit 1..100).
  Future<RemotePayload<OrdersPageModel>> getOrders({
    required int page,
    required int limit,
  });

  /// `GET /v1/orders/{orderId}`.
  Future<RemotePayload<OrderModel>> getOrder(String orderId);

  /// `POST /v1/orders/{orderId}/cancel { reason, note? }` → the order.
  Future<RemotePayload<OrderModel>> cancelOrder(
    String orderId,
    Map<String, dynamic> body,
  );

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
  Future<RemotePayload<OrdersPageModel>> getOrders({
    required int page,
    required int limit,
  }) async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.orders,
        queryParameters: <String, dynamic>{pageField: page, limitField: limit},
      ),
      _listRoute,
    );
    return RemotePayload(
      OrdersPageModel.fromJson(results, requestedPage: page),
      results,
    );
  }

  @override
  Future<RemotePayload<OrderModel>> getOrder(String orderId) async {
    final results = ApiPayload.asMap(
      await _api.get(EndPoints.order(orderId)),
      _detailRoute,
    );
    return RemotePayload(OrderModel.fromJson(results), results);
  }

  @override
  Future<RemotePayload<OrderModel>> cancelOrder(
    String orderId,
    Map<String, dynamic> body,
  ) async {
    final results = ApiPayload.asMap(
      await _api.post(EndPoints.orderCancel(orderId), body: body),
      _detailRoute,
    );
    return RemotePayload(OrderModel.fromJson(results), results);
  }

  @override
  Future<void> submitReview(Map<String, dynamic> body) =>
      _api.post(EndPoints.reviews, body: body);
}
