import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/content_page_model.dart';

/// Public routes (Bearer optional). Receives the envelope's `results`
/// (unwrapped by `DioConsumer`); throws `AppException` only. The offers
/// are the shared catalogue read (`CatalogRemoteDataSource.fetchOffers`):
/// the product page, the checkout and the offers page share one copy.
abstract class PromotionsRemoteDataSource {
  /// `GET /v1/pages/:slug` — the slug is an enum on the backend. Comes back
  /// with its raw `results`, which the repository keeps on the device.
  Future<RemotePayload<ContentPageModel>> getPage(String slug);
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  const PromotionsRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  @override
  Future<RemotePayload<ContentPageModel>> getPage(String slug) async {
    final path = EndPoints.page(slug);
    final results = ApiPayload.asMap(await _api.get(path), path);
    return RemotePayload(ContentPageModel.fromJson(results), results);
  }
}
