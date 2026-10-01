import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';

/// A flat, metric view of the ground around [origin]: metres east (`x`) and
/// north (`y`). An equirectangular projection — well under a metre off over
/// a city ride of a few kilometres, and cheap enough to run every frame.
class GeoMetricFrame extends Equatable {
  const GeoMetricFrame(this.origin);

  final GeoPointEntity origin;

  /// Metres in one degree of latitude (and of longitude at the equator).
  static const double metersPerDegree = 111320;

  static const double _radiansPerDegree = math.pi / 180;

  double get _metersPerDegreeLng =>
      metersPerDegree * math.cos(origin.lat * _radiansPerDegree);

  math.Point<double> toMeters(GeoPointEntity point) => math.Point<double>(
    (point.lng - origin.lng) * _metersPerDegreeLng,
    (point.lat - origin.lat) * metersPerDegree,
  );

  GeoPointEntity toPoint(math.Point<double> meters) => GeoPointEntity(
    lat: origin.lat + meters.y / metersPerDegree,
    lng: origin.lng + meters.x / _metersPerDegreeLng,
  );

  @override
  List<Object?> get props => [origin];
}
