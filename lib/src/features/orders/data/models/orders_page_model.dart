import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/order_model.dart';

/// `GET /v1/orders` → `{ data: [Order], pagination: { total, page, limit,
/// hasMore } }`. A malformed row is skipped, never the page.
class OrdersPageModel {
  const OrdersPageModel({
    required this.items,
    required this.page,
    this.hasMore = false,
    this.total = 0,
  });

  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';
  static const String pageKey = 'page';
  static const String hasMoreKey = 'hasMore';
  static const String _logName = 'OrdersPageModel';

  factory OrdersPageModel.fromJson(
    Map<String, dynamic> json, {
    required int requestedPage,
  }) {
    final pagination = JsonRead.object(json[paginationKey]);
    return OrdersPageModel(
      items: JsonRead.rows(
        json[dataKey],
        OrderModel.fromJson,
        logName: _logName,
      ),
      page: pagination == null
          ? requestedPage
          : JsonRead.integer(pagination[pageKey]) ?? requestedPage,
      hasMore: pagination != null && JsonRead.flag(pagination[hasMoreKey]),
      total: pagination == null
          ? 0
          : JsonRead.integer(pagination[totalKey]) ?? 0,
    );
  }

  final List<OrderModel> items;
  final int page;
  final bool hasMore;
  final int total;
}
