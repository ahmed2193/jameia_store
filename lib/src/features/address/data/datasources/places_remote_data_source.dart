import 'dart:math' as math;

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_headers.dart';
import '../../../../core/network/external_api_consumer.dart';
import '../../../../core/network/external_end_points.dart';
import '../models/geo_point_model.dart';
import '../models/place_details_model.dart';
import '../models/place_prediction_model.dart';

/// Google Places API (New): autocomplete and the point of a picked place.
///
/// The keystrokes of one search and the look-up that ends it share one
/// session token (a UUID v4), so Google bills them as one session; a search
/// left without a pick is ended with [endSession]. Kuwait only, biased to
/// where the map looks, in the app's language. The look-up asks for
/// Essentials fields only (the point and the short address).
abstract class PlacesRemoteDataSource {
  /// `POST https://places.googleapis.com/v1/places:autocomplete`.
  Future<List<PlacePredictionModel>> autocomplete(
    String input, {
    required String languageCode,
    GeoPointModel? near,
  });

  /// `GET https://places.googleapis.com/v1/places/{placeId}` — ends the
  /// session.
  Future<PlaceDetailsModel> details(
    String placeId, {
    required String languageCode,
  });

  /// The search closed without a pick: the next keystroke starts a new
  /// session.
  void endSession();
}

class PlacesRemoteDataSourceImpl implements PlacesRemoteDataSource {
  PlacesRemoteDataSourceImpl(
    this._api, {
    required this.apiKey,
    math.Random? random,
  }) : _random = random ?? math.Random.secure();

  final ExternalApiConsumer _api;
  final String apiKey;
  final math.Random _random;

  String? _session;

  static const Duration timeout = Duration(seconds: 6);

  /// Kuwait (ccTLD), the only country the app delivers in.
  static const String regionCode = 'kw';

  /// How far around the map's middle the answers lean (m).
  static const double biasRadiusMeters = 30000;

  static const String autocompleteFieldMask =
      'suggestions.placePrediction.placeId,'
      'suggestions.placePrediction.text,'
      'suggestions.placePrediction.structuredFormat,'
      'suggestions.placePrediction.distanceMeters';
  static const String detailsFieldMask = 'location';

  static const String inputKey = 'input';
  static const String sessionTokenKey = 'sessionToken';
  static const String languageCodeKey = 'languageCode';
  static const String regionCodeKey = 'regionCode';
  static const String includedRegionCodesKey = 'includedRegionCodes';
  static const String locationBiasKey = 'locationBias';
  static const String circleKey = 'circle';
  static const String centerKey = 'center';
  static const String radiusKey = 'radius';
  static const String originKey = 'origin';

  @override
  Future<List<PlacePredictionModel>> autocomplete(
    String input, {
    required String languageCode,
    GeoPointModel? near,
  }) async {
    final reply = await _api.post(
      ExternalEndPoints.googlePlacesAutocomplete,
      timeout: timeout,
      headers: _headers(autocompleteFieldMask),
      body: <String, dynamic>{
        inputKey: input,
        sessionTokenKey: _session ??= _newSessionToken(),
        languageCodeKey: languageCode,
        regionCodeKey: regionCode,
        includedRegionCodesKey: const [regionCode],
        if (near != null) ...{
          locationBiasKey: {
            circleKey: {
              centerKey: near.toGoogleJson(),
              radiusKey: biasRadiusMeters,
            },
          },
          originKey: near.toGoogleJson(),
        },
      },
    );
    if (reply is! Map) {
      throw const ParsingException('places autocomplete: no object');
    }
    return PlacePredictionModel.listFromReply(reply.cast<String, dynamic>());
  }

  @override
  Future<PlaceDetailsModel> details(
    String placeId, {
    required String languageCode,
  }) async {
    final session = _session;
    _session = null;
    final reply = await _api.get(
      ExternalEndPoints.googlePlace(placeId),
      timeout: timeout,
      headers: _headers(detailsFieldMask),
      queryParameters: <String, dynamic>{
        languageCodeKey: languageCode,
        regionCodeKey: regionCode,
        sessionTokenKey: ?session,
      },
    );
    if (reply is! Map) {
      throw const ParsingException('place details: no object');
    }
    return PlaceDetailsModel.fromJson(reply.cast<String, dynamic>());
  }

  @override
  void endSession() => _session = null;

  Map<String, String> _headers(String fieldMask) => <String, String>{
    ApiHeaders.googleApiKey: apiKey,
    ApiHeaders.googleFieldMask: fieldMask,
  };

  /// A random (version 4) UUID: 36 URL-safe characters.
  String _newSessionToken() {
    final bytes = List<int>.generate(_uuidBytes, (_) => _random.nextInt(256));
    bytes[_versionByte] = (bytes[_versionByte] & 0x0f) | 0x40;
    bytes[_variantByte] = (bytes[_variantByte] & 0x3f) | 0x80;
    final hex = [
      for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static const int _uuidBytes = 16;
  static const int _versionByte = 6;
  static const int _variantByte = 8;
}
