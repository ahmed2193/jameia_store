import 'dart:math' as math;

import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import '../mappers/encoded_polyline.dart';
import 'courier_point_model.dart';

/// A route on the real road network through the stops of a ride (the
/// rider's start → the store → the door): one [legs] entry per pair of
/// stops, from the road service that answered ([source]).
class RoadRouteModel {
  const RoadRouteModel({required this.legs, required this.source});

  /// A Google Routes API `computeRoutes` reply: `routes[0].legs[]`, each with
  /// `polyline.encodedPolyline` (precision 5), `distanceMeters`, `duration`
  /// (`"123s"`) and traffic per polyline interval
  /// (`travelAdvisory.speedReadingIntervals[]`: `startPolylinePointIndex`,
  /// `endPolylinePointIndex`, `speed` NORMAL / SLOW / TRAFFIC_JAM).
  factory RoadRouteModel.fromGoogleJson(Map<String, dynamic> json) {
    final legs = <RoadLegModel>[
      for (final leg in _rows(_firstRoute(json)?[legsKey]))
        RoadLegModel._fromGoogle(leg),
    ];
    return RoadRouteModel._checked(legs, googleSource);
  }

  /// An OSRM `route` reply (`overview=full&geometries=polyline6&
  /// annotations=distance,duration`): the whole road as one `polyline6`,
  /// split at the points nearest each inner waypoint; each stretch's pace
  /// is its annotation distance / duration.
  factory RoadRouteModel.fromOsrmJson(Map<String, dynamic> json) {
    final route = _firstRoute(json);
    final geometry = JsonRead.string(route?[geometryKey]);
    if (route == null || geometry == null) {
      throw const ParsingException('road route without a geometry');
    }
    final points = _decode(geometry, EncodedPolyline.osrmPrecision);
    final osrmLegs = _rows(route[legsKey]);
    final stops = [
      for (final waypoint in _rows(json[waypointsKey]))
        ?_osrmLocation(waypoint[locationKey]),
    ];
    final paces = [for (final leg in osrmLegs) ..._osrmPaces(leg)];
    final hasPaces = paces.length == points.length - 1;
    final legs = <RoadLegModel>[];
    var from = 0;
    for (var i = 0; i < osrmLegs.length; i++) {
      final last = i == osrmLegs.length - 1;
      final to = last
          ? points.length - 1
          : i + 1 < stops.length
          ? _nearest(points, stops[i + 1], from)
          : from;
      legs.add(
        RoadLegModel(
          points: points.sublist(from, to + 1),
          paces: hasPaces ? paces.sublist(from, to) : const <double>[],
        ),
      );
      from = to;
    }
    return RoadRouteModel._checked(legs, osmSource);
  }

  factory RoadRouteModel._checked(List<RoadLegModel> legs, String source) {
    if (legs.isEmpty ||
        legs.any((leg) => leg.points.length < RoadLegModel.minPoints)) {
      throw const ParsingException('road route without a drivable leg');
    }
    return RoadRouteModel(legs: legs, source: source);
  }

  static const String routesKey = 'routes';
  static const String legsKey = 'legs';
  static const String geometryKey = 'geometry';
  static const String waypointsKey = 'waypoints';
  static const String locationKey = 'location';
  static const String annotationKey = 'annotation';
  static const String distanceKey = 'distance';
  static const String durationKey = 'duration';

  /// Where the route came from — Google, or OpenStreetMap roads (OSRM).
  static const String googleSource = 'google';
  static const String osmSource = 'osm';

  final List<RoadLegModel> legs;
  final String source;

  static Map<String, dynamic>? _firstRoute(Map<String, dynamic> json) {
    final routes = _rows(json[routesKey]);
    return routes.isEmpty ? null : routes.first;
  }

  static List<Map<String, dynamic>> _rows(Object? value) => [
    if (value is List)
      for (final row in value)
        if (row is Map) row.cast<String, dynamic>(),
  ];

  static List<CourierPointModel> _decode(String encoded, int precision) {
    try {
      return EncodedPolyline.decode(encoded, precision: precision);
    } on FormatException catch (error) {
      throw ParsingException('road route: ${error.message}');
    }
  }

  /// OSRM `[lng, lat]`.
  static CourierPointModel? _osrmLocation(Object? value) {
    if (value is! List || value.length < 2) return null;
    final lng = JsonRead.decimal(value[0]);
    final lat = JsonRead.decimal(value[1]);
    return lat == null || lng == null
        ? null
        : CourierPointModel(lat: lat, lng: lng);
  }

  static List<double> _osrmPaces(Map<String, dynamic> leg) {
    final annotation = JsonRead.object(leg[annotationKey]);
    final distances = annotation?[distanceKey];
    final durations = annotation?[durationKey];
    if (distances is! List || durations is! List) return const <double>[];
    if (distances.length != durations.length) return const <double>[];
    return [
      for (var i = 0; i < distances.length; i++)
        RoadLegModel.paceOf(
          JsonRead.decimal(distances[i]),
          JsonRead.decimal(durations[i]),
        ),
    ];
  }

  /// The index (from [from] on) of the point of [points] nearest [stop].
  static int _nearest(
    List<CourierPointModel> points,
    CourierPointModel stop,
    int from,
  ) {
    var best = from;
    var bestGap = double.infinity;
    for (var i = from; i < points.length; i++) {
      final dLat = points[i].lat - stop.lat;
      final dLng = points[i].lng - stop.lng;
      final gap = dLat * dLat + dLng * dLng;
      if (gap < bestGap) {
        bestGap = gap;
        best = i;
      }
    }
    return best;
  }
}

/// One leg of a [RoadRouteModel]: its road, and how fast each stretch
/// between two points of it is driven, in m/s ([paces] — one per stretch,
/// or empty when the service does not say).
class RoadLegModel {
  const RoadLegModel({required this.points, this.paces = const <double>[]});

  factory RoadLegModel._fromGoogle(Map<String, dynamic> json) {
    final polyline = JsonRead.object(json[polylineKey]);
    final encoded = JsonRead.string(polyline?[encodedPolylineKey]);
    if (encoded == null) {
      throw const ParsingException('road leg without a polyline');
    }
    final points = RoadRouteModel._decode(
      encoded,
      EncodedPolyline.googlePrecision,
    );
    final meters = JsonRead.decimal(json[distanceMetersKey]);
    final seconds = _seconds(JsonRead.string(json[RoadRouteModel.durationKey]));
    final average = meters == null || seconds == null
        ? null
        : paceOf(meters, seconds);
    if (average == null || points.length < minPoints) {
      return RoadLegModel(points: points);
    }
    final paces = List<double>.filled(points.length - 1, average);
    final advisory = JsonRead.object(json[travelAdvisoryKey]);
    for (final interval in RoadRouteModel._rows(
      advisory?[speedReadingIntervalsKey],
    )) {
      final start = JsonRead.integer(interval[startIndexKey]) ?? 0;
      final end = JsonRead.integer(interval[endIndexKey]) ?? 0;
      final share = switch (JsonRead.string(interval[speedKey])) {
        slowSpeed => _slowShare,
        jamSpeed => _jamShare,
        _ => _freeShare,
      };
      for (var i = math.max(0, start); i < math.min(end, paces.length); i++) {
        paces[i] = average * share;
      }
    }
    return RoadLegModel(points: points, paces: paces);
  }

  static const String polylineKey = 'polyline';
  static const String encodedPolylineKey = 'encodedPolyline';
  static const String distanceMetersKey = 'distanceMeters';
  static const String travelAdvisoryKey = 'travelAdvisory';
  static const String speedReadingIntervalsKey = 'speedReadingIntervals';
  static const String startIndexKey = 'startPolylinePointIndex';
  static const String endIndexKey = 'endPolylinePointIndex';
  static const String speedKey = 'speed';
  static const String slowSpeed = 'SLOW';
  static const String jamSpeed = 'TRAFFIC_JAM';

  /// A leg needs a start and an end.
  static const int minPoints = 2;

  // Pace on a traffic interval, as a share of the leg's average pace.
  static const double _freeShare = 1.1;
  static const double _slowShare = 0.55;
  static const double _jamShare = 0.25;

  static const String _secondsSuffix = 's';

  final List<CourierPointModel> points;
  final List<double> paces;

  /// [meters] over [seconds] (0 when either is missing or not positive).
  static double paceOf(double? meters, double? seconds) =>
      meters == null || seconds == null || seconds <= 0 || meters <= 0
      ? 0
      : meters / seconds;

  /// Google's protobuf duration: `"123s"` / `"12.5s"`.
  static double? _seconds(String? value) {
    if (value == null || !value.endsWith(_secondsSuffix)) return null;
    return double.tryParse(value.substring(0, value.length - 1));
  }
}
