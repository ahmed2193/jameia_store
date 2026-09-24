import '../../../../core/data/models/json_read.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/content_page_model.dart';
import '../models/offer_model.dart';

/// Public routes (Bearer optional). Receives the envelope's `results`
/// (unwrapped by `DioConsumer`); throws `AppException` only.
abstract class PromotionsRemoteDataSource {
  /// `GET /v1/offers?page&limit` — one page is the whole list in practice
  /// ([maxOffers] is the backend's cap).
  Future<List<OfferModel>> getOffers();

  /// `GET /v1/pages/:slug` — the slug is an enum on the backend.
  Future<ContentPageModel> getPage(String slug);
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  const PromotionsRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String dataKey = 'data';
  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const int maxOffers = 100;
  static const String _logName = 'PromotionsRemoteDataSource';

  @override
  Future<List<OfferModel>> getOffers() async {
    final results = await _api.get(
      EndPoints.offers,
      queryParameters: <String, dynamic>{pageField: 1, limitField: maxOffers},
    );
    final payload = ApiPayload.asMap(results, EndPoints.offers);
    return JsonRead.rows(
      payload[dataKey],
      OfferModel.fromJson,
      logName: _logName,
    );
  }

  @override
  Future<ContentPageModel> getPage(String slug) async {
    final path = EndPoints.page(slug);
    final results = await _api.get(path);
    return ContentPageModel.fromJson(ApiPayload.asMap(results, path));
  }
}
