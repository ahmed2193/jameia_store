import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/pinned_place.dart';
import '../entities/place_spot.dart';
import '../entities/place_suggestion.dart';

/// Places on the map: what a pin points at, and the search by name.
///
/// Google Places (New) answers when the app was built with a Maps key;
/// otherwise Kuwait's districts by name, then the device's own geocoder.
/// Every answer is in [languageCode] (`en` / `ar`).
abstract class PlacesRepository {
  /// What [point] is: the street-level parts the geocoder knows.
  Future<Either<Failure, PinnedPlace>> resolve(
    GeoPointEntity point, {
    required String languageCode,
  });

  /// Places matching [input], the nearest to [near] first when given.
  Future<Either<Failure, List<PlaceSuggestion>>> suggest(
    String input, {
    required String languageCode,
    GeoPointEntity? near,
  });

  /// Every district the app knows, A to Z in [languageCode]: where Hero
  /// delivers, before anything is typed; with how far each is from [near]
  /// when it is given.
  Either<Failure, List<PlaceSuggestion>> deliveryAreas({
    required String languageCode,
    GeoPointEntity? near,
  });

  /// Where [suggestion] is (a look-up for a Google answer; ends the search
  /// session it belonged to).
  Future<Either<Failure, PlaceSpot>> locate(
    PlaceSuggestion suggestion, {
    required String languageCode,
  });

  /// The customer left the search without picking a place: the next search
  /// starts a new session.
  Either<Failure, Unit> endSearch();
}
