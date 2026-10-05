import '../../../../core/error/exceptions.dart';
import 'geo_point_model.dart';

/// A Google Places (New) place, as far as the map needs it: its point
/// (`GET places/{id}`, Essentials fields only).
class PlaceDetailsModel {
  const PlaceDetailsModel({required this.location});

  /// A place without a point cannot be shown: [ParsingException].
  factory PlaceDetailsModel.fromJson(Map<String, dynamic> json) {
    final location = GeoPointModel.fromGoogleJson(json[locationKey]);
    if (location == null) {
      throw const ParsingException('place details without a location');
    }
    return PlaceDetailsModel(location: location);
  }

  static const String locationKey = 'location';

  final GeoPointModel location;
}
