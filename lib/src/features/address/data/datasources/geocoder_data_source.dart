import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart' show PlatformException;
import 'package:geocoding/geocoding.dart' as geo;

import '../../../../core/error/exceptions.dart';
import '../models/geo_point_model.dart';
import '../models/placemark_model.dart';

/// The device's own geocoder (Android `Geocoder`, Apple `CLGeocoder`): free,
/// no key, in the language asked for. An empty list when it knows nothing
/// there; [NetworkException] when it cannot answer (offline, no geocoder on
/// the device), [RequestTimeoutException] past [timeout].
abstract class GeocoderDataSource {
  /// What is at the point, best answer first.
  Future<List<PlacemarkModel>> reverse(
    GeoPointModel point, {
    required String languageCode,
  });

  /// Points for an address typed in full.
  Future<List<GeoPointModel>> forward(
    String query, {
    required String languageCode,
  });
}

class GeocoderDataSourceImpl implements GeocoderDataSource {
  const GeocoderDataSourceImpl();

  static const Duration timeout = Duration(seconds: 6);

  /// iOS reports every miss of its geocoder — "no result" included —
  /// under this code (Android answers an empty list).
  static const String _appleMiss = 'GeocodeAddressError';

  @override
  Future<List<PlacemarkModel>> reverse(
    GeoPointModel point, {
    required String languageCode,
  }) => _ask(() async {
    // geocoding 5 drops a locale given to the constructor: pass it per call.
    final marks = await geo.Geocoding().placemarkFromCoordinates(
      point.lat,
      point.lng,
      locale: Locale(languageCode),
    );
    return [for (final mark in marks) _model(mark)];
  });

  @override
  Future<List<GeoPointModel>> forward(
    String query, {
    required String languageCode,
  }) => _ask(() async {
    final found = await geo.Geocoding().locationFromAddress(
      query,
      locale: Locale(languageCode),
    );
    return [
      for (final location in found)
        GeoPointModel(lat: location.latitude, lng: location.longitude),
    ];
  });

  /// Runs [lookup] within [timeout]; "nothing found" is an empty list. The
  /// `Geocoding()` constructor throws where no geocoder is registered (unit
  /// tests, an unsupported platform): that is [NetworkException] too.
  static Future<List<T>> _ask<T>(Future<List<T>> Function() lookup) async {
    try {
      return await lookup().timeout(timeout);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on PlatformException catch (error) {
      if (error.code == _appleMiss) return <T>[];
      throw NetworkException(error.message ?? error.code);
    } catch (error) {
      throw NetworkException(error.toString());
    }
  }

  static PlacemarkModel _model(geo.Placemark mark) =>
      PlacemarkModel.fromGeocoder(
        name: mark.name,
        street: mark.street,
        thoroughfare: mark.thoroughfare,
        subThoroughfare: mark.subThoroughfare,
        subLocality: mark.subLocality,
        locality: mark.locality,
        subAdministrativeArea: mark.subAdministrativeArea,
        administrativeArea: mark.administrativeArea,
        country: mark.country,
      );
}
