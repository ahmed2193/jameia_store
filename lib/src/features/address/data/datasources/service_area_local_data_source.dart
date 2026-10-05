import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import '../models/service_area_model.dart';

/// Where Hero delivers. The backend serves every pin through a
/// "Kuwait — countrywide" zone and has no read-only coverage check
/// (`POST /v1/delivery/resolve-location` patches the cart), so the app
/// keeps Kuwait's boundary itself: the OpenStreetMap outline jm3eia_mobile
/// ships, bundled as [asset] (ODbL — credited on the licences page).
abstract class ServiceAreaLocalDataSource {
  /// The boundary, read once. Throws [CacheException] when the file cannot be
  /// read, [ParsingException] when it holds no boundary.
  Future<ServiceAreaModel> area();
}

class ServiceAreaLocalDataSourceImpl implements ServiceAreaLocalDataSource {
  ServiceAreaLocalDataSourceImpl(this._bundle);

  final AssetBundle _bundle;

  static const String asset = 'assets/data/kuwait_boundary.json';

  /// The read itself is kept, so pickers asking at the same time share it;
  /// a failed one is let go, so the next picker tries again.
  Future<ServiceAreaModel>? _area;

  @override
  Future<ServiceAreaModel> area() => _area ??= _read();

  Future<ServiceAreaModel> _read() async {
    try {
      final String raw;
      try {
        // Kept here, parsed: the bundle need not keep the text too.
        raw = await _bundle.loadString(asset, cache: false);
      } on FlutterError catch (error) {
        // The asset is missing from the bundle.
        throw CacheException('service area: $error');
      } on Exception catch (error) {
        throw CacheException('service area: $error');
      }
      final json = JsonRead.object(_decode(raw));
      if (json == null) {
        throw const ParsingException('service area: not an object');
      }
      return ServiceAreaModel.fromJson(json);
    } on AppException {
      _area = null;
      rethrow;
    }
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      throw const ParsingException('service area: not JSON');
    }
  }
}
