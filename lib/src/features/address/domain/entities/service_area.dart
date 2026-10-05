import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';

/// Where Hero delivers: Kuwait — its land, its islands and its territorial
/// sea — as rings on the map. A pin outside cannot be saved as a delivery
/// address.
class ServiceArea extends Equatable {
  const ServiceArea(this.rings);

  /// The outline's rings — outer edges and holes alike — each its corners in
  /// order, the last one joining the first.
  final List<List<GeoPointEntity>> rings;

  /// Whether [point] lies inside: within an odd number of rings (the
  /// even-odd rule), so a hole cuts its ring out and separate pieces (an
  /// island drawn on its own) each count.
  bool contains(GeoPointEntity point) {
    var inside = false;
    for (final ring in rings) {
      if (_encloses(ring, point)) inside = !inside;
    }
    return inside;
  }

  /// Ray casting: a ray from [point] crosses the ring's edge an odd number
  /// of times when the ring encloses it.
  static bool _encloses(List<GeoPointEntity> ring, GeoPointEntity point) {
    if (ring.length < _minCorners) return false;
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      final straddles = (a.lat > point.lat) != (b.lat > point.lat);
      if (!straddles) continue;
      final crossLng =
          a.lng + (point.lat - a.lat) * (b.lng - a.lng) / (b.lat - a.lat);
      if (point.lng < crossLng) inside = !inside;
    }
    return inside;
  }

  static const int _minCorners = 3;

  @override
  List<Object?> get props => [rings];
}
