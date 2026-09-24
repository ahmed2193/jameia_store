import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/product_detail_model.dart';
import '../models/product_reviews_model.dart';

/// Public routes (Bearer optional). Receives the envelope's `results`
/// (unwrapped by `DioConsumer`); throws `AppException` only.
abstract class ProductDetailsRemoteDataSource {
  /// `GET /v1/products/:slug` — `404 RESOURCE_NOT_FOUND` for an unknown slug.
  Future<ProductDetailModel> getProduct(String slug);

  /// `GET /v1/products/:slug/reviews?page&limit`.
  Future<ProductReviewsModel> getReviews({
    required String slug,
    required int page,
    required int limit,
  });
}

class ProductDetailsRemoteDataSourceImpl
    implements ProductDetailsRemoteDataSource {
  const ProductDetailsRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';

  @override
  Future<ProductDetailModel> getProduct(String slug) async {
    final path = EndPoints.product(slug);
    final results = await _api.get(path);
    return ProductDetailModel.fromJson(ApiPayload.asMap(results, path));
  }

  @override
  Future<ProductReviewsModel> getReviews({
    required String slug,
    required int page,
    required int limit,
  }) async {
    final path = EndPoints.productReviews(slug);
    final results = await _api.get(
      path,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    return ProductReviewsModel.fromJson(
      ApiPayload.asMap(results, path),
      requestedPage: page,
    );
  }
}
