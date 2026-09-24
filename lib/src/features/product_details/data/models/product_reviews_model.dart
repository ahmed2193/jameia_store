import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `results` of `GET /v1/products/:slug/reviews`:
/// `{ data[], pagination{ total, page, limit, hasMore }, ratingAverage, ratingCount }`.
class ProductReviewsModel {
  const ProductReviewsModel({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';
  static const String pageKey = 'page';
  static const String hasMoreKey = 'hasMore';
  static const String ratingAverageKey = 'ratingAverage';
  static const String ratingCountKey = 'ratingCount';
  static const String _logName = 'ProductReviewsModel';

  /// [requestedPage] fills in when the backend omits `pagination`. A malformed
  /// review is skipped.
  factory ProductReviewsModel.fromJson(
    Map<String, dynamic> json, {
    int requestedPage = 1,
  }) {
    final data = json[dataKey];
    if (data is! List) throw const ParsingException('reviews: data missing');
    final items = JsonRead.rows(
      data,
      ProductReviewModel.fromJson,
      logName: _logName,
    );
    final pagination =
        JsonRead.object(json[paginationKey]) ?? const <String, dynamic>{};
    return ProductReviewsModel(
      items: items,
      total: JsonRead.integer(pagination[totalKey]) ?? items.length,
      page: JsonRead.integer(pagination[pageKey]) ?? requestedPage,
      hasMore: JsonRead.flag(pagination[hasMoreKey]),
      ratingAverage: JsonRead.decimal(json[ratingAverageKey]) ?? 0,
      ratingCount: JsonRead.integer(json[ratingCountKey]) ?? 0,
    );
  }

  final List<ProductReviewModel> items;
  final int total;
  final int page;
  final bool hasMore;
  final double ratingAverage;
  final int ratingCount;
}

/// One review row: `{ _id, rating, title?, body?, customerName, createdAt }`.
class ProductReviewModel {
  const ProductReviewModel({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.title = '',
    this.body = '',
    this.customerName = '',
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String ratingKey = 'rating';
  static const String titleKey = 'title';
  static const String bodyKey = 'body';
  static const String customerNameKey = 'customerName';
  static const String createdAtKey = 'createdAt';

  /// Throws [ParsingException] without an id or a readable date.
  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('review: id missing');
    final createdAt = JsonRead.dateTime(json[createdAtKey]);
    if (createdAt == null) {
      throw const ParsingException('review: bad createdAt');
    }
    return ProductReviewModel(
      id: id,
      rating: JsonRead.integer(json[ratingKey]) ?? 0,
      createdAt: createdAt,
      title: JsonRead.string(json[titleKey]) ?? '',
      body: JsonRead.string(json[bodyKey]) ?? '',
      customerName: JsonRead.string(json[customerNameKey]) ?? '',
    );
  }

  final String id;
  final int rating;
  final DateTime createdAt;
  final String title;
  final String body;
  final String customerName;
}
