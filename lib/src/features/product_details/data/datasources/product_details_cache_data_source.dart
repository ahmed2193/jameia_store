import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/product_detail_model.dart';
import '../models/product_reviews_model.dart';

/// The product pages as last shown — the product and the first page of its
/// reviews, per slug and language. Public: the same for every customer.
/// Parsed back with the DTOs' own `fromJson`.
abstract class ProductDetailsCacheDataSource {
  /// `GET /v1/products/:slug`.
  CacheSlot<ProductDetailModel>? detail(String slug);

  /// `GET /v1/products/:slug/reviews` — the first page of [limit].
  CacheSlot<ProductReviewsModel>? reviews(String slug, {required int limit});
}

class ProductDetailsCacheDataSourceImpl
    implements ProductDetailsCacheDataSource {
  const ProductDetailsCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;

  /// One entry per product (and language): the oldest go past 60.
  static const CacheNamespace detailNamespace = CacheNamespace(
    'product.detail',
    scope: CacheScope.public,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 3),
    maxEntries: 60,
  );

  static const CacheNamespace reviewsNamespace = CacheNamespace(
    'product.reviews',
    scope: CacheScope.public,
    freshFor: Duration(minutes: 5),
    maxAge: Duration(days: 7),
    maxEntries: 60,
  );

  @override
  CacheSlot<ProductDetailModel>? detail(String slug) => _slots.of(
    detailNamespace,
    id: slug,
    parse: (raw) => ProductDetailModel.fromJson(
      ApiPayload.asMap(raw, EndPoints.product(slug)),
    ),
  );

  @override
  CacheSlot<ProductReviewsModel>? reviews(String slug, {required int limit}) =>
      _slots.of(
        reviewsNamespace,
        id: '$slug|$limit',
        parse: (raw) => ProductReviewsModel.fromJson(
          ApiPayload.asMap(raw, EndPoints.productReviews(slug)),
          requestedPage: _firstPage,
        ),
      );
}
