import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/home_feed_model.dart';
import '../models/home_init_model.dart';
import '../models/home_orders_count_model.dart';

/// Public routes (Bearer optional → personalised), plus the signed-in
/// customer's order count. Receives the envelope's `results` (unwrapped by
/// `DioConsumer`); throws `AppException` only. The home and init replies come
/// back with their raw `results`, which the repository caches as sent.
abstract class HomeRemoteDataSource {
  /// `GET /v1/home` — slides, ordered sections, category tree, announcement.
  Future<RemotePayload<HomeFeedModel>> getHome();

  /// `GET /v1/init` — the launch snapshot; home reads store / delivery / popups.
  Future<RemotePayload<HomeInitModel>> getInit();

  /// `GET /v1/orders?page=1&limit=1` (customer) → `pagination.total`: one
  /// row, only the count is read.
  Future<int> countOrders();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';

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

  @override
  Future<int> countOrders() async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.orders,
        queryParameters: <String, dynamic>{pageField: 1, limitField: 1},
      ),
      EndPoints.orders,
    );
    return HomeOrdersCountModel.fromJson(results).total;
  }
}
