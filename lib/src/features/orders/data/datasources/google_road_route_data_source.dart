import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_headers.dart';
import '../../../../core/network/external_api_consumer.dart';
import '../../../../core/network/external_end_points.dart';
import '../models/road_route_model.dart';
import 'road_route_data_source.dart';

/// Google Routes API: the road with live traffic (`TRAFFIC_AWARE`), with
/// traffic per stretch (`TRAFFIC_ON_POLYLINE`) — asked for only the fields
/// the ride uses, since the API bills by what is asked. Needs the Routes API
/// enabled for [apiKey]'s project.
class GoogleRoadRouteDataSource implements RoadRouteDataSource {
  const GoogleRoadRouteDataSource(this._api, {required this.apiKey});

  final ExternalApiConsumer _api;
  final String apiKey;

  static const String fieldMask =
      'routes.legs.polyline.encodedPolyline,'
      'routes.legs.distanceMeters,'
      'routes.legs.duration,'
      'routes.legs.travelAdvisory.speedReadingIntervals';

  static const String originKey = 'origin';
  static const String destinationKey = 'destination';
  static const String intermediatesKey = 'intermediates';
  static const String locationKey = 'location';
  static const String latLngKey = 'latLng';
  static const String latitudeKey = 'latitude';
  static const String longitudeKey = 'longitude';
  static const String travelModeKey = 'travelMode';
  static const String routingPreferenceKey = 'routingPreference';
  static const String polylineQualityKey = 'polylineQuality';
  static const String extraComputationsKey = 'extraComputations';

  static const String driveMode = 'DRIVE';
  static const String trafficAware = 'TRAFFIC_AWARE';
  static const String highQuality = 'HIGH_QUALITY';
  static const String trafficOnPolyline = 'TRAFFIC_ON_POLYLINE';

  /// `POST https://routes.googleapis.com/directions/v2:computeRoutes`.
  @override
  Future<RoadRouteModel> route(
    List<GeoPointEntity> stops, {
    Duration? timeout,
  }) async {
    final reply = await _api.post(
      ExternalEndPoints.googleComputeRoutes,
      timeout: timeout,
      headers: <String, String>{
        ApiHeaders.googleApiKey: apiKey,
        ApiHeaders.googleFieldMask: fieldMask,
      },
      body: <String, dynamic>{
        originKey: _waypoint(stops.first),
        destinationKey: _waypoint(stops.last),
        intermediatesKey: [
          for (final stop in stops.sublist(1, stops.length - 1))
            _waypoint(stop),
        ],
        travelModeKey: driveMode,
        routingPreferenceKey: trafficAware,
        polylineQualityKey: highQuality,
        extraComputationsKey: [trafficOnPolyline],
      },
    );
    if (reply is! Map) throw const ParsingException('road route: no object');
    return RoadRouteModel.fromGoogleJson(reply.cast<String, dynamic>());
  }

  static Map<String, dynamic> _waypoint(GeoPointEntity point) => {
    locationKey: {
      latLngKey: {latitudeKey: point.lat, longitudeKey: point.lng},
    },
  };
}
