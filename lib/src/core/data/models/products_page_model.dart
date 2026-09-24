import '../../error/exceptions.dart';
import 'json_read.dart';
import 'product_model.dart';

/// `results` of `GET /v1/products`:
/// `{ data: [Product], pagination: { total, page, limit, hasMore } }`.
/// Shared by every feature that lists products (shop, search, discovery).
class ProductsPageModel {
  const ProductsPageModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';
  static const String pageKey = 'page';
  static const String limitKey = 'limit';
  static const String hasMoreKey = 'hasMore';
  static const String _logName = 'ProductsPageModel';

  /// [requestedPage] fills in when the backend omits `pagination`. A malformed
  /// row is skipped so one bad product never blanks the list.
  factory ProductsPageModel.fromJson(
    Map<String, dynamic> json, {
    int requestedPage = 1,
  }) {
    final data = json[dataKey];
    if (data is! List) throw const ParsingException('products: data missing');
    final items = JsonRead.rows(data, ProductModel.fromJson, logName: _logName);
    final pagination =
        JsonRead.object(json[paginationKey]) ?? const <String, dynamic>{};
    return ProductsPageModel(
      items: items,
      total: JsonRead.integer(pagination[totalKey]) ?? items.length,
      page: JsonRead.integer(pagination[pageKey]) ?? requestedPage,
      limit: JsonRead.integer(pagination[limitKey]) ?? items.length,
      hasMore: JsonRead.flag(pagination[hasMoreKey]),
    );
  }

  final List<ProductModel> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
}
