// The place search offers only places Hero delivers to.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_spot.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_suggestion.dart';
import 'package:hero_mart/src/features/address/domain/entities/service_area.dart';
import 'package:hero_mart/src/features/address/domain/repositories/places_repository.dart';
import 'package:hero_mart/src/features/address/domain/repositories/service_area_repository.dart';
import 'package:hero_mart/src/features/address/domain/usecases/search_places_usecase.dart';

class _FakePlaces implements PlacesRepository {
  Either<Failure, List<PlaceSuggestion>> answers = const Right([]);
  final List<String> asked = [];

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> suggest(
    String input, {
    required String languageCode,
    GeoPointEntity? near,
  }) async {
    asked.add(input);
    return answers;
  }

  @override
  Future<Either<Failure, PinnedPlace>> resolve(
    GeoPointEntity point, {
    required String languageCode,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, PlaceSpot>> locate(
    PlaceSuggestion suggestion, {
    required String languageCode,
  }) => throw UnimplementedError();

  @override
  Either<Failure, Unit> endSearch() => const Right(unit);

  @override
  Either<Failure, List<PlaceSuggestion>> deliveryAreas({
    required String languageCode,
    GeoPointEntity? near,
  }) => const Right([]);
}

class _FakeServiceArea implements ServiceAreaRepository {
  Either<Failure, ServiceArea> area = const Right(_square);

  @override
  Future<Either<Failure, ServiceArea>> serviceArea() async => area;
}

/// A square around (29.5, 47.5).
const ServiceArea _square = ServiceArea([
  [
    GeoPointEntity(lat: 29, lng: 47),
    GeoPointEntity(lat: 30, lng: 47),
    GeoPointEntity(lat: 30, lng: 48),
    GeoPointEntity(lat: 29, lng: 48),
  ],
]);

const PlaceSuggestion _inside = PlaceSuggestion(
  id: 'in',
  title: 'Inside',
  location: GeoPointEntity(lat: 29.5, lng: 47.5),
  source: PlaceSource.area,
);
const PlaceSuggestion _outside = PlaceSuggestion(
  id: 'out',
  title: 'salmi',
  location: GeoPointEntity(lat: 2.1, lng: 45.3),
  source: PlaceSource.geocoder,
);
const PlaceSuggestion _google = PlaceSuggestion(
  id: 'g1',
  title: 'Marina Mall',
  source: PlaceSource.google,
);

void main() {
  late _FakePlaces places;
  late _FakeServiceArea area;
  late SearchPlacesUseCase search;

  setUp(() {
    places = _FakePlaces();
    area = _FakeServiceArea();
    search = SearchPlacesUseCase(places, area);
  });

  List<PlaceSuggestion> answersOf(
    Either<Failure, List<PlaceSuggestion>> result,
  ) => result.fold((failure) => fail('unexpected $failure'), (it) => it);

  const params = SearchPlacesParams(input: 'sal', languageCode: 'en');

  test('an answer outside the delivery area is never offered', () async {
    places.answers = const Right([_inside, _outside]);

    expect(answersOf(await search(params)), [_inside]);
  });

  test('an answer with no point yet is kept: the map checks it', () async {
    places.answers = const Right([_google]);

    expect(answersOf(await search(params)), [_google]);
  });

  test('with no known area every answer stays', () async {
    area.area = const Left(CacheFailure('no outline'));
    places.answers = const Right([_inside, _outside]);

    expect(answersOf(await search(params)), [_inside, _outside]);
  });

  test('a failure stays a failure', () async {
    places.answers = const Left(NetworkFailure('offline'));

    expect((await search(params)).isLeft(), isTrue);
  });

  test('one letter asks nothing', () async {
    final result = await search(
      const SearchPlacesParams(input: ' s ', languageCode: 'en'),
    );

    expect(answersOf(result), isEmpty);
    expect(places.asked, isEmpty);
  });
}
