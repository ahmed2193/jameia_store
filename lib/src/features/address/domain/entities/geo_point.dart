import 'package:equatable/equatable.dart';

/// Framework-free geographic point (`{double lat, double lng}`).
///
/// Owned by the address feature so the domain entities never import
/// `google_maps_flutter`'s `LatLng` (the leak the region picker previously
/// carried via `ServiceRegionItem.anchor`). The data layer maps this to/from
/// `LatLng` in the mappers; presentation/map screens keep using `LatLng`
/// directly (that coupling is fine there).
class GeoPointEntity extends Equatable {
  const GeoPointEntity({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}
