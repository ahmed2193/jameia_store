import 'package:equatable/equatable.dart';

/// Framework-free geographic point (`{double lat, double lng}`).
///
/// Keeps `google_maps_flutter`'s `LatLng` out of the domain. The data layer
/// converts to/from `LatLng` in `core/data/mappers/geo_point_mapper.dart`.
class GeoPointEntity extends Equatable {
  const GeoPointEntity({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}
