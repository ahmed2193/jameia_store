import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../domain/entities/geo_point_entity.dart';

/// `google_maps_flutter` [LatLng] ⇄ [GeoPointEntity]. Confines the map SDK
/// type to the data layer.
extension LatLngMapper on LatLng {
  GeoPointEntity toEntity() => GeoPointEntity(lat: latitude, lng: longitude);
}

extension GeoPointEntityMapper on GeoPointEntity {
  LatLng toLatLng() => LatLng(lat, lng);
}
