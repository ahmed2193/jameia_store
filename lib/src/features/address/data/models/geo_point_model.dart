import '../../../../core/data/models/json_read.dart';

/// A point on the map as the data sources pass it around.
class GeoPointModel {
  const GeoPointModel({required this.lat, required this.lng});

  /// Google's `LatLng` object (`{latitude, longitude}`); `null` when either
  /// is missing.
  static GeoPointModel? fromGoogleJson(Object? json) {
    final map = JsonRead.object(json);
    final lat = JsonRead.decimal(map?[latitudeKey]);
    final lng = JsonRead.decimal(map?[longitudeKey]);
    if (lat == null || lng == null) return null;
    return GeoPointModel(lat: lat, lng: lng);
  }

  static const String latitudeKey = 'latitude';
  static const String longitudeKey = 'longitude';

  final double lat;
  final double lng;

  Map<String, dynamic> toGoogleJson() => <String, dynamic>{
    latitudeKey: lat,
    longitudeKey: lng,
  };
}
