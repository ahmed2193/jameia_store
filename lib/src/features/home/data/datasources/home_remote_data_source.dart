import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/home_feed_model.dart';
import '../models/home_init_model.dart';

/// Public routes (Bearer optional → personalised). Receives the envelope's
/// `results` (unwrapped by `DioConsumer`); throws `AppException` only. Both
/// replies come back with their raw `results`, which the repository caches
/// as sent.
abstract class HomeRemoteDataSource {
  /// `GET /v1/home` — slides, ordered sections, category tree, announcement.
  Future<RemotePayload<HomeFeedModel>> getHome();

  /// `GET /v1/init` — the launch snapshot; home reads store / delivery / popups.
  Future<RemotePayload<HomeInitModel>> getInit();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  @override
  Future<RemotePayload<HomeFeedModel>> getHome() async {
    final results = ApiPayload.asMap(
      await _api.get(EndPoints.home),
      EndPoints.home,
    );
    return RemotePayload(HomeFeedModel.fromJson(results), results);
  }

  @override
  Future<RemotePayload<HomeInitModel>> getInit() async {
    final results = ApiPayload.asMap(
      await _api.get(EndPoints.init),
      EndPoints.init,
    );
    return RemotePayload(HomeInitModel.fromJson(results), results);
  }
}
