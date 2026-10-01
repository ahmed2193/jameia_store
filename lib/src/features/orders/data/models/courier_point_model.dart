import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `{ lat, lng }` — one point of the rider feed (a corner of the road, a
/// fix). Both coordinates are its identity: without one it is no point.
class CourierPointModel {
  const CourierPointModel({required this.lat, required this.lng});

  factory CourierPointModel.fromJson(Map<String, dynamic> json) {
    final lat = JsonRead.decimal(json[latKey]);
    final lng = JsonRead.decimal(json[lngKey]);
    if (lat == null || lng == null) {
      throw const ParsingException('courier point without lat / lng');
    }
    return CourierPointModel(lat: lat, lng: lng);
  }

  static const String latKey = 'lat';
  static const String lngKey = 'lng';

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => <String, dynamic>{latKey: lat, lngKey: lng};
}
