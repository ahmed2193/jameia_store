import '../../../../core/data/models/json_read.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/external_api_consumer.dart';
import '../../../../core/network/external_end_points.dart';
import '../models/road_route_model.dart';
import 'road_route_data_source.dart';

/// OSRM on OpenStreetMap roads (`AppEnv.osrmBaseUrl`): the full-detail road
/// as `polyline6`, with each stretch's distance and duration so the
/// simulated rider rides a main road faster than a side street.
class OsrmRoadRouteDataSource implements RoadRouteDataSource {
  const OsrmRoadRouteDataSource(this._api);

  final ExternalApiConsumer _api;

  static const String codeKey = 'code';
  static const String okCode = 'Ok';
  static const String overviewField = 'overview';
  static const String geometriesField = 'geometries';
  static const String annotationsField = 'annotations';
  static const String fullOverview = 'full';
  static const String polyline6 = 'polyline6';
  static const String distanceAndDuration = 'distance,duration';

  /// Coordinates to 6 decimals (≈ 0.1 m) keep the URL short.
  static const int _decimals = 6;

  /// `GET {osrm}/route/v1/driving/{lng,lat;…}`.
  @override
  Future<RoadRouteModel> route(
    List<GeoPointEntity> stops, {
    Duration? timeout,
  }) async {
    final coordinates = [
      for (final stop in stops)
        '${stop.lng.toStringAsFixed(_decimals)},'
            '${stop.lat.toStringAsFixed(_decimals)}',
    ].join(';');
    final reply = await _api.get(
      ExternalEndPoints.osrmRoute(coordinates),
      queryParameters: <String, dynamic>{
        overviewField: fullOverview,
        geometriesField: polyline6,
        annotationsField: distanceAndDuration,
      },
      timeout: timeout,
    );
    if (reply is! Map) throw const ParsingException('road route: no object');
    final json = reply.cast<String, dynamic>();
    final code = JsonRead.string(json[codeKey]);
    if (code != okCode) throw NotFoundException('no road route: $code');
    return RoadRouteModel.fromOsrmJson(json);
  }
}
