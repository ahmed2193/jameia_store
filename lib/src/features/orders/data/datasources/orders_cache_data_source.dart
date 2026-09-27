import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/data/models/order_model.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/orders_page_model.dart';

/// The signed-in customer's orders as last shown: the first page of the
/// list and each order opened (tracking, invoice, review), per language.
/// Customer-only — nothing is kept for a guest — and wiped on sign-out.
/// Parsed back with the DTOs' own `fromJson`.
abstract class OrdersCacheDataSource {
  /// `GET /v1/orders` — the first page of [limit].
  CacheSlot<OrdersPageModel>? firstPage({required int limit});

  /// `GET /v1/orders/{orderId}`.
  CacheSlot<OrderModel>? order(String orderId);

  /// Forgets every saved first page: an order changed on the server (a
  /// cancel), so a saved list must not be served as fresh.
  Future<void> forgetPages();
}

class OrdersCacheDataSourceImpl implements OrdersCacheDataSource {
  const OrdersCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;

  static const CacheNamespace listNamespace = CacheNamespace(
    'orders.list',
    scope: CacheScope.customer,
    freshFor: Duration(seconds: 30),
    maxAge: Duration(days: 30),
  );

  /// Never fresh — an order moves, so the server is always asked; the copy
  /// shows while it answers, or instead of it offline. One entry per order
  /// (and language): the oldest go past 30.
  static const CacheNamespace detailNamespace = CacheNamespace(
    'orders.detail',
    scope: CacheScope.customer,
    freshFor: Duration.zero,
    maxAge: Duration(days: 30),
    maxEntries: 30,
  );

  @override
  Future<void> forgetPages() => _slots.forget(listNamespace);

  @override
  CacheSlot<OrdersPageModel>? firstPage({required int limit}) => _slots.of(
    listNamespace,
    id: '$limit',
    parse: (raw) => OrdersPageModel.fromJson(
      ApiPayload.asMap(raw, EndPoints.orders),
      requestedPage: _firstPage,
    ),
  );

  @override
  CacheSlot<OrderModel>? order(String orderId) => _slots.of(
    detailNamespace,
    id: orderId,
    parse: (raw) =>
        OrderModel.fromJson(ApiPayload.asMap(raw, EndPoints.order(orderId))),
  );
}
