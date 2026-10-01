import '../../../../core/domain/entities/geo_point_entity.dart';
import '../models/road_route_model.dart';

/// Routes on the real road network, for the live map's simulated rider.
abstract class RoadRouteDataSource {
  /// The road through [stops] (two or more), one leg per pair of stops.
  /// Given a [timeout], a request that runs longer is aborted (not merely no
  /// longer awaited) and throws `RequestTimeoutException`.
  Future<RoadRouteModel> route(List<GeoPointEntity> stops, {Duration? timeout});
}
