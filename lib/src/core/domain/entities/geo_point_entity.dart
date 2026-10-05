import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Framework-free geographic point (`{double lat, double lng}`).
///
/// Keeps `google_maps_flutter`'s `LatLng` out of the domain; the data and
/// presentation layers convert at their edges.
class GeoPointEntity extends Equatable {
  const GeoPointEntity({required this.lat, required this.lng});

  final double lat;
  final double lng;

  /// Kuwait City: where an address without a pin points, and where a map
  /// with nowhere better to look opens.
  static const GeoPointEntity kuwaitCity = GeoPointEntity(
    lat: 29.3759,
    lng: 47.9774,
  );

  static const double _earthRadiusMeters = 6371000;
  static const double _radiansPerDegree = math.pi / 180;

  /// Metres along the earth's surface to [other] (haversine).
  double metersTo(GeoPointEntity other) {
    final dLat = (other.lat - lat) * _radiansPerDegree;
    final dLng = (other.lng - lng) * _radiansPerDegree;
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat * _radiansPerDegree) *
            math.cos(other.lat * _radiansPerDegree) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }

  @override
  List<Object?> get props => [lat, lng];
}
