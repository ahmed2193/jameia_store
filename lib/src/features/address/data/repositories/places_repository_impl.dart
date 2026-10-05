import 'dart:collection';
import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/localization/localized_pick.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/known_area.dart';
import '../../domain/entities/pinned_place.dart';
import '../../domain/entities/place_spot.dart';
import '../../domain/entities/place_suggestion.dart';
import '../../domain/entities/text_match.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/geocoder_data_source.dart';
import '../datasources/known_areas_local_data_source.dart';
import '../datasources/places_remote_data_source.dart';
import '../mappers/geo_point_model_mapper.dart';
import '../mappers/known_area_mapper.dart';
import '../mappers/place_mapper.dart';
import '../mappers/placemark_mapper.dart';
import 'resolved_places_memo.dart';

/// [PlacesRepository] over Google Places (New) when the app has a Maps key
/// ([google] non-null), the device's geocoder, and Kuwait's districts.
///
/// * resolve — the geocoder; when it cannot answer the pin is just a point
///   (no guessed area or street is ever written into the form). Answers are
///   kept ([ResolvedPlacesMemo]).
/// * suggest — Google's answer when Google answered; otherwise the
///   districts whose name holds the words ([KnownArea.matches]), nearest
///   first, each over its governorate, then the geocoder's match for the
///   whole text — asked in Kuwait (the device geocoder has no region
///   filter), and not at all when the text names a district — read back
///   like a pin (the same kept answers), so it shows a place's own name and
///   the address there; a spot the map knows nothing about (no district,
///   street or name: a stray match in the desert) is left out. A failure
///   only surfaces when nothing at all matched.
class PlacesRepositoryImpl
    with BaseRepositoryMixin
    implements PlacesRepository {
  PlacesRepositoryImpl({
    required this._geocoder,
    required this._areas,
    this._google,
  });

  final GeocoderDataSource _geocoder;
  final KnownAreasLocalDataSource _areas;
  final PlacesRemoteDataSource? _google;
  final ResolvedPlacesMemo _resolved = ResolvedPlacesMemo();

  /// Kuwait's districts, made once.
  late final List<KnownArea> _known = _areas.areas().toEntities();

  /// The geocoder's points per text and language, for as long as the app
  /// runs: typing back to an earlier text asks nothing (iOS throttles its
  /// geocoder). The least recently used text goes first.
  final LinkedHashMap<String, List<GeoPointEntity>> _found =
      LinkedHashMap<String, List<GeoPointEntity>>();
  static const int _foundCapacity = 32;

  static const int _maxAreaAnswers = 5;
  static const int _maxGeocoderAnswers = 1;
  static const String _logName = 'places';
  static const String _areaIdPrefix = 'area:';
  static const String _geocoderIdPrefix = 'geocoder:';

  /// The country a typed address is looked for in.
  static const String _countryEn = 'Kuwait';
  static const String _countryAr = 'الكويت';

  @override
  Future<Either<Failure, PinnedPlace>> resolve(
    GeoPointEntity point, {
    required String languageCode,
  }) => execute(
    () async => await _read(point, languageCode) ?? PinnedPlace.at(point),
  );

  /// What the map reads at [point]: the kept answer, else the geocoder's
  /// (kept when it says anything); `null` when the geocoder could not be
  /// asked or said nothing at all there (iOS answers every failure, offline
  /// included, with nothing).
  Future<PinnedPlace?> _read(GeoPointEntity point, String languageCode) async {
    final kept = _resolved.at(point, languageCode);
    if (kept != null) return kept;
    try {
      final marks = await _geocoder.reverse(
        point.toModel(),
        languageCode: languageCode,
      );
      if (marks.isEmpty) return null;
      final place = marks.toPinnedPlace(point);
      if (!place.isBare) _resolved.keep(point, languageCode, place);
      return place;
    } on AppException catch (error) {
      log('reverse geocode failed: $error', name: _logName);
      return null;
    }
  }

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> suggest(
    String input, {
    required String languageCode,
    GeoPointEntity? near,
  }) => execute(() async {
    final google = _google;
    AppException? failure;
    if (google != null) {
      try {
        final rows = await google.autocomplete(
          input,
          languageCode: languageCode,
          near: near?.toModel(),
        );
        return rows.toEntities();
      } on AppException catch (error) {
        log('google autocomplete failed: $error', name: _logName);
        failure = error;
      }
    }
    final districts = [
      for (final area in _known)
        if (area.matches(input)) area,
    ];
    final answers = _areaAnswers(districts, input, languageCode, near);
    if (!districts.any((area) => area.isNamedBy(input))) {
      try {
        final country = pickLocalized(
          languageCode,
          en: _countryEn,
          ar: _countryAr,
        );
        final points = await _forward('$input, $country', languageCode);
        for (final at in points.take(_maxGeocoderAnswers)) {
          final place = await _read(at, languageCode);
          // Read, and nothing known there: a stray match.
          if (place != null && place.isBare) continue;
          answers.add(
            _geocoderAnswer(input, place ?? PinnedPlace.at(at), near),
          );
        }
      } on AppException catch (error) {
        failure ??= error;
      }
    }
    final reason = failure;
    if (answers.isEmpty && reason != null) throw reason;
    return answers;
  });

  @override
  Either<Failure, List<PlaceSuggestion>> deliveryAreas({
    required String languageCode,
    GeoPointEntity? near,
  }) => executeSync(() {
    final sorted = [
      for (final area in _known)
        (area: area, key: area.sortKeyFor(languageCode)),
    ]..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final (:area, key: _) in sorted)
        PlaceSuggestion(
          id: '$_areaIdPrefix${area.id}',
          title: area.nameFor(languageCode),
          subtitle: area.governorateFor(languageCode),
          distanceMeters: near?.metersTo(area.location).round(),
          location: area.location,
          source: PlaceSource.area,
        ),
    ];
  });

  @override
  Future<Either<Failure, PlaceSpot>> locate(
    PlaceSuggestion suggestion, {
    required String languageCode,
  }) => execute(() async {
    final point = suggestion.location;
    final google = _google;
    if (point != null) {
      google?.endSession();
      return PlaceSpot(
        location: point,
        title: suggestion.title,
        isArea: suggestion.source == PlaceSource.area,
      );
    }
    if (google == null) {
      throw const ParsingException('a Google answer without Google');
    }
    final details = await google.details(
      suggestion.id,
      languageCode: languageCode,
    );
    return details.toSpot(suggestion);
  });

  /// The geocoder's points for [query]: the kept ones, else asked (a miss
  /// is kept too; a failure is not).
  Future<List<GeoPointEntity>> _forward(
    String query,
    String languageCode,
  ) async {
    final key = '$languageCode|$query';
    final kept = _found.remove(key);
    if (kept != null) return _found[key] = kept;
    final points = [
      for (final point in await _geocoder.forward(
        query,
        languageCode: languageCode,
      ))
        point.toEntity(),
    ];
    _found[key] = points;
    if (_found.length > _foundCapacity) _found.remove(_found.keys.first);
    return points;
  }

  @override
  Either<Failure, Unit> endSearch() => executeSync(() {
    _google?.endSession();
    return unit;
  });

  /// The geocoder's match for [input], named by what the map reads there
  /// ([place]), as Google Maps names it: a place's own name, else its
  /// street, else the words typed.
  static PlaceSuggestion _geocoderAnswer(
    String input,
    PinnedPlace place,
    GeoPointEntity? near,
  ) {
    final typed = input.trim();
    final title = place.name.isNotEmpty
        ? place.name
        : place.street.isNotEmpty
        ? place.street
        : typed;
    final point = place.location;
    return PlaceSuggestion(
      id: '$_geocoderIdPrefix${point.lat},${point.lng}',
      title: title,
      titleMatches: TextMatch.wordStartsIn(title, typed),
      distanceMeters: near?.metersTo(point).round(),
      location: point,
      place: place,
      source: PlaceSource.geocoder,
    );
  }

  /// [districts] as answers in [languageCode] over their governorate, the
  /// typed words in bold, the nearest to [near] first.
  static List<PlaceSuggestion> _areaAnswers(
    List<KnownArea> districts,
    String input,
    String languageCode,
    GeoPointEntity? near,
  ) {
    final typed = input.trim();
    final answers = [
      for (final area in districts)
        PlaceSuggestion(
          id: '$_areaIdPrefix${area.id}',
          title: area.nameFor(languageCode),
          subtitle: area.governorateFor(languageCode),
          titleMatches: TextMatch.wordStartsIn(
            area.nameFor(languageCode),
            typed,
          ),
          distanceMeters: near?.metersTo(area.location).round(),
          location: area.location,
          source: PlaceSource.area,
        ),
    ];
    if (near != null) {
      answers.sort(
        (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
      );
    }
    return answers.take(_maxAreaAnswers).toList();
  }
}
