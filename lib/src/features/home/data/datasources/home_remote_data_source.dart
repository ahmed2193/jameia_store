import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/home_feed_model.dart';
import '../models/home_init_model.dart';

/// Public routes (Bearer optional → personalised). Receives the envelope's
/// `results` (unwrapped by `DioConsumer`); throws `AppException` only.
abstract class HomeRemoteDataSource {
  /// `GET /v1/home` — slides, ordered sections, category tree, announcement.
  Future<HomeFeedModel> getHome();

  /// `GET /v1/init` — the launch snapshot; home reads store / delivery / popups.
  Future<HomeInitModel> getInit();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  @override
  Future<HomeFeedModel> getHome() async {
    final results = await _api.get(EndPoints.home);
    return HomeFeedModel.fromJson(ApiPayload.asMap(results, EndPoints.home));
  }

  @override
  Future<HomeInitModel> getInit() async {
    final results = await _api.get(EndPoints.init);
    return HomeInitModel.fromJson(ApiPayload.asMap(results, EndPoints.init));
  }
}
