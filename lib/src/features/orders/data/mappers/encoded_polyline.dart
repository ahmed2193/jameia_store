import '../models/courier_point_model.dart';

/// Google's encoded polyline format (also OSRM's `polyline6`): each value is
/// the delta from the previous one, times 10^precision, zigzag-encoded in
/// 5-bit chunks offset by 63 into printable characters. Precision 5 for
/// Google, 6 for OSRM `polyline6`.
abstract final class EncodedPolyline {
  static const int googlePrecision = 5;
  static const int osrmPrecision = 6;

  static const int _offset = 63;
  static const int _chunkBits = 5;
  static const int _chunkMask = 0x1F;
  static const int _moreFlag = 0x20;
  static const int _base = 10;

  /// The points of [encoded]; an empty list for an empty string. A string
  /// cut off mid-value throws a [FormatException].
  static List<CourierPointModel> decode(
    String encoded, {
    int precision = googlePrecision,
  }) {
    var factor = 1;
    for (var i = 0; i < precision; i++) {
      factor *= _base;
    }
    final points = <CourierPointModel>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    int next() {
      var result = 0;
      var shift = 0;
      int chunk;
      do {
        if (index >= encoded.length) {
          throw const FormatException('polyline cut off mid-value');
        }
        chunk = encoded.codeUnitAt(index++) - _offset;
        result |= (chunk & _chunkMask) << shift;
        shift += _chunkBits;
      } while (chunk >= _moreFlag);
      return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    }

    while (index < encoded.length) {
      lat += next();
      lng += next();
      points.add(CourierPointModel(lat: lat / factor, lng: lng / factor));
    }
    return points;
  }
}
