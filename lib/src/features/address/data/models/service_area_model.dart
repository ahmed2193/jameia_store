import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'geo_point_model.dart';

/// Where Hero delivers, as the bundled boundary file holds it — the file
/// jm3eia_mobile ships (`assets/geo/kuwait_boundary.json`, schema 1):
/// OpenStreetMap relation 305099, Kuwait with its islands and territorial
/// sea, under `core` as a GeoJSON MultiPolygon of `[lng, lat]` pairs.
///
/// The file's `buffered` outline (the same, 20 km wider) is not read: past
/// Kuwait's sea it only reaches Umm Qasr, Safwan and Khafji, which jm3eia
/// turns away again with a coverage check Hero has no counterpart for.
class ServiceAreaModel {
  const ServiceAreaModel({required this.version, required this.rings});

  /// Every ring of `core` — outer edges and holes — without the closing
  /// corner that repeats the first. Throws [ParsingException] for another
  /// schema, a missing version or a malformed outline: half an outline
  /// would turn real addresses away.
  factory ServiceAreaModel.fromJson(Map<String, dynamic> json) {
    if (JsonRead.integer(json[schemaVersionKey]) != schemaVersion) {
      throw const ParsingException('service area: unknown schema');
    }
    final version = JsonRead.string(json[versionKey]);
    if (version == null) {
      throw const ParsingException('service area: no version');
    }
    final polygons = JsonRead.object(json[coreKey])?[coordinatesKey];
    if (polygons is! List || polygons.isEmpty) {
      throw const ParsingException('service area: no outline');
    }
    return ServiceAreaModel(
      version: version,
      rings: [
        for (final polygon in polygons)
          for (final ring in _list(polygon)) _ring(ring),
      ],
    );
  }

  static const int schemaVersion = 1;
  static const String schemaVersionKey = 'schemaVersion';
  static const String versionKey = 'version';
  static const String coreKey = 'core';
  static const String coordinatesKey = 'coordinates';

  static const int _minCorners = 3;

  /// The boundary's own version (`YYYY-MM-DD.revision`).
  final String version;
  final List<List<GeoPointModel>> rings;

  static List<Object?> _list(Object? value) {
    if (value is! List) {
      throw const ParsingException('service area: not a list');
    }
    return value;
  }

  static List<GeoPointModel> _ring(Object? value) {
    final corners = [for (final position in _list(value)) _corner(position)];
    final closed =
        corners.length > 1 &&
        corners.first.lat == corners.last.lat &&
        corners.first.lng == corners.last.lng;
    if (closed) corners.removeLast();
    if (corners.length < _minCorners) {
      throw const ParsingException('service area: a ring too short');
    }
    return corners;
  }

  /// A GeoJSON position: longitude first.
  static GeoPointModel _corner(Object? value) {
    final position = _list(value);
    final lng = position.isNotEmpty ? JsonRead.decimal(position[0]) : null;
    final lat = position.length > 1 ? JsonRead.decimal(position[1]) : null;
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      throw const ParsingException('service area: a bad corner');
    }
    return GeoPointModel(lat: lat, lng: lng);
  }
}
