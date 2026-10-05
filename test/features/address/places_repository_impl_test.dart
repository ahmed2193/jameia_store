// The places repository: who answers a pin and a search (Google when the
// app has a key, then the device geocoder, then Kuwait's districts), what is
// kept, and what a failure looks like.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/data/datasources/geocoder_data_source.dart';
import 'package:hero_mart/src/features/address/data/datasources/known_areas_local_data_source.dart';
import 'package:hero_mart/src/features/address/data/datasources/places_remote_data_source.dart';
import 'package:hero_mart/src/features/address/data/models/geo_point_model.dart';
import 'package:hero_mart/src/features/address/data/models/place_details_model.dart';
import 'package:hero_mart/src/features/address/data/models/place_prediction_model.dart';
import 'package:hero_mart/src/features/address/data/models/placemark_model.dart';
import 'package:hero_mart/src/features/address/data/repositories/places_repository_impl.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_spot.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_suggestion.dart';
import 'package:hero_mart/src/features/address/domain/entities/text_match.dart';

class _FakeGeocoder implements GeocoderDataSource {
  List<PlacemarkModel> marks = const [];
  List<GeoPointModel> points = const [];
  AppException? error;

  /// Only the read back fails.
  AppException? reverseError;
  final List<String> reverseLanguages = [];
  final List<String> forwardQueries = [];
  int get forwardCalls => forwardQueries.length;

  @override
  Future<List<PlacemarkModel>> reverse(
    GeoPointModel point, {
    required String languageCode,
  }) async {
    reverseLanguages.add(languageCode);
    final failed = reverseError ?? error;
    if (failed != null) throw failed;
    return marks;
  }

  @override
  Future<List<GeoPointModel>> forward(
    String query, {
    required String languageCode,
  }) async {
    forwardQueries.add(query);
    final failed = error;
    if (failed != null) throw failed;
    return points;
  }
}

class _FakeGoogle implements PlacesRemoteDataSource {
  List<PlacePredictionModel> predictions = const [];
  PlaceDetailsModel details_ = const PlaceDetailsModel(
    location: GeoPointModel(lat: 29.33, lng: 48.07),
  );
  AppException? error;
  int sessionsEnded = 0;
  final List<String> detailsAsked = [];

  @override
  Future<List<PlacePredictionModel>> autocomplete(
    String input, {
    required String languageCode,
    GeoPointModel? near,
  }) async {
    final failed = error;
    if (failed != null) throw failed;
    return predictions;
  }

  @override
  Future<PlaceDetailsModel> details(
    String placeId, {
    required String languageCode,
  }) async {
    detailsAsked.add(placeId);
    return details_;
  }

  @override
  void endSession() => sessionsEnded++;
}

void main() {
  late _FakeGeocoder geocoder;
  late _FakeGoogle google;

  const pin = GeoPointEntity(lat: 29.334, lng: 48.078);
  const salmiyaMark = PlacemarkModel(
    thoroughfare: 'Salem Al Mubarak St',
    subThoroughfare: '14',
    subLocality: 'Salmiya',
  );

  PlacesRepositoryImpl build({bool withGoogle = false}) => PlacesRepositoryImpl(
    geocoder: geocoder,
    areas: const KnownAreasLocalDataSourceImpl(),
    google: withGoogle ? google : null,
  );

  T right<T>(Either<Failure, T> result) =>
      result.fold((failure) => fail('unexpected $failure'), (value) => value);

  setUp(() {
    geocoder = _FakeGeocoder();
    google = _FakeGoogle();
  });

  group('resolve', () {
    test(
      'reads the pin through the geocoder, once per spot and language',
      () async {
        geocoder.marks = const [salmiyaMark];
        final places = build();

        final first = right(await places.resolve(pin, languageCode: 'en'));
        // The same spot to a metre: kept.
        final again = right(
          await places.resolve(
            const GeoPointEntity(lat: 29.334001, lng: 48.078001),
            languageCode: 'en',
          ),
        );
        await places.resolve(pin, languageCode: 'ar');

        expect(first.area, 'Salmiya');
        expect(first.street, 'Salem Al Mubarak St');
        expect(again.street, first.street);
        expect(geocoder.reverseLanguages, ['en', 'ar']);
      },
    );

    test(
      'a geocoder that cannot answer leaves the bare point, not kept',
      () async {
        geocoder.error = const NoInternetConnectionException();
        final places = build();

        final place = right(await places.resolve(pin, languageCode: 'en'));
        expect(place, const PinnedPlace.at(pin));

        geocoder
          ..error = null
          ..marks = const [salmiyaMark];
        final later = right(await places.resolve(pin, languageCode: 'en'));
        expect(later.area, 'Salmiya');
      },
    );
  });

  group('suggest', () {
    test("Google's answers when Google answers", () async {
      google.predictions = const [
        PlacePredictionModel(
          placeId: 'p1',
          mainText: 'Marina Mall',
          secondaryText: 'Salmiya',
          mainMatches: [(start: 0, end: 4)],
          distanceMeters: 900,
        ),
      ];
      final places = build(withGoogle: true);

      final answers = right(
        await places.suggest('mari', languageCode: 'en', near: pin),
      );

      expect(answers, const [
        PlaceSuggestion(
          id: 'p1',
          title: 'Marina Mall',
          subtitle: 'Salmiya',
          titleMatches: [TextMatch(0, 4)],
          distanceMeters: 900,
          source: PlaceSource.google,
        ),
      ]);
      expect(geocoder.forwardCalls, 0);
    });

    test(
      'Google failing: the districts, then the geocoder asked in Kuwait',
      () async {
        google.error = const RequestTimeoutException();
        geocoder.points = const [GeoPointModel(lat: 29.29, lng: 48.07)];
        geocoder.marks = const [PlacemarkModel(subLocality: 'Salwa')];
        final places = build(withGoogle: true);

        final answers = right(
          await places.suggest('salw', languageCode: 'en', near: pin),
        );

        expect(answers.first.source, PlaceSource.area);
        expect(answers.first.title, 'Salwa');
        expect(answers.last.source, PlaceSource.geocoder);
        expect(answers.last.title, 'salw');
        expect(
          answers.last.location,
          const GeoPointEntity(lat: 29.29, lng: 48.07),
        );
        // Read back like a pin: the district there goes under it.
        expect(answers.last.place?.area, 'Salwa');
        expect(geocoder.forwardQueries, ['salw, Kuwait']);

        right(await places.suggest('سلو', languageCode: 'ar'));
        expect(geocoder.forwardQueries.last, 'سلو, الكويت');
      },
    );

    test('a district named in full asks the geocoder nothing', () async {
      geocoder.points = const [GeoPointModel(lat: 29.29, lng: 48.07)];
      final places = build();

      final answers = right(
        await places.suggest('Sabah Al Salem', languageCode: 'en'),
      );

      expect(answers.map((answer) => answer.source), [PlaceSource.area]);
      expect(geocoder.forwardCalls, 0);
    });

    test(
      'districts match however the name is written, in both languages',
      () async {
        final places = build();
        for (final typed in [
          'sabah al salem',
          'Sabah Al-Salem',
          'صباح السالم',
        ]) {
          final answers = right(
            await places.suggest(typed, languageCode: 'en'),
          );
          expect(
            answers.map((answer) => answer.title),
            contains('Sabah Al-Salem'),
            reason: typed,
          );
        }
        final arabic = right(
          await places.suggest('الجابرية', languageCode: 'ar'),
        );
        expect(arabic.map((answer) => answer.title), contains('الجابرية'));
      },
    );

    test(
      'a spot the geocoder found is read back like a pin: named by the '
      'place there, the address there under it, and kept for the pin',
      () async {
        const tower = GeoPointEntity(lat: 29.3786, lng: 47.9925);
        geocoder.points = const [GeoPointModel(lat: 29.3786, lng: 47.9925)];
        geocoder.marks = const [
          PlacemarkModel(
            name: 'Al Hamra Tower',
            thoroughfare: 'Al Shuhada St',
            subLocality: 'Sharq',
          ),
        ];
        final places = build();

        final found = right(
          await places.suggest('hamra', languageCode: 'en', near: pin),
        ).single;

        expect(found.source, PlaceSource.geocoder);
        expect(found.title, 'Al Hamra Tower');
        expect(found.titleMatches, const [TextMatch(3, 8)]);
        expect(found.place?.street, 'Al Shuhada St');
        expect(found.place?.area, 'Sharq');
        expect(found.location, tower);
        expect(found.distanceMeters, greaterThan(0));
        expect(geocoder.reverseLanguages, ['en']);

        // The picker reading that spot once the map is there asks nothing.
        final read = right(await places.resolve(tower, languageCode: 'en'));
        expect(read.name, 'Al Hamra Tower');
        expect(geocoder.reverseLanguages, ['en']);
      },
    );

    test('a found spot with no name of its own keeps the words typed, over '
        'the area there', () async {
      geocoder.points = const [GeoPointModel(lat: 29.29, lng: 48.07)];
      geocoder.marks = const [PlacemarkModel(subLocality: 'Salwa')];
      final places = build();

      final found = right(
        await places.suggest(' gulf road ', languageCode: 'en'),
      ).single;

      expect(found.title, 'gulf road');
      expect(found.titleMatches, const [TextMatch(0, 4), TextMatch(5, 9)]);
      expect(found.place?.area, 'Salwa');
    });

    test('a found spot with no name is titled by its street, the typed '
        'words that start its words in bold', () async {
      geocoder.points = const [GeoPointModel(lat: 29.37, lng: 47.98)];
      geocoder.marks = const [
        PlacemarkModel(thoroughfare: 'Arabian Gulf St', subLocality: 'Sharq'),
      ];
      final places = build();

      final found = right(await places.suggest('gulf road', languageCode: 'en'))
          .single;

      expect(found.title, 'Arabian Gulf St');
      expect(found.titleMatches, const [TextMatch(8, 12)]);
      expect(found.place?.street, 'Arabian Gulf St');
    });

    test('a found spot that cannot be read back is still an answer, under '
        'the words typed', () async {
      geocoder.points = const [GeoPointModel(lat: 29.29, lng: 48.07)];
      geocoder.reverseError = const RequestTimeoutException();
      final places = build();

      final found = right(await places.suggest('gulf road', languageCode: 'en'))
          .single;
      expect(found.title, 'gulf road');
      expect(
        found.place,
        PinnedPlace.at(const GeoPointEntity(lat: 29.29, lng: 48.07)),
      );
    });

    test('a stray match the map knows nothing about is left out', () async {
      // What the Android geocoder answers for "sal, الكويت": a road with no
      // name in the Jahra desert.
      geocoder.points = const [GeoPointModel(lat: 29.3117, lng: 47.4818)];
      geocoder.marks = const [
        PlacemarkModel(
          name: 'طريق بدون اسم',
          street: 'طريق بدون اسم، الكويت',
          thoroughfare: 'طريق بدون اسم',
          administrativeArea: 'الجهراء',
          country: 'الكويت',
        ),
        PlacemarkModel(
          name: 'الجهراء',
          street: 'الجهراء، الكويت',
          administrativeArea: 'الجهراء',
          country: 'الكويت',
        ),
        PlacemarkModel(name: 'الكويت', street: 'الكويت', country: 'الكويت'),
      ];
      final places = build();

      final answers = right(
        await places.suggest('sal', languageCode: 'ar', near: pin),
      );

      expect(geocoder.forwardQueries, ['sal, الكويت']);
      expect(answers, isNotEmpty);
      expect(
        answers.map((answer) => answer.source),
        everyElement(PlaceSource.area),
      );
      expect(answers.map((answer) => answer.title), contains('السالمية'));
    });

    test(
      'a found spot the geocoder says nothing at all about is still an '
      'answer (iOS answers every failure, offline included, with nothing)',
      () async {
        geocoder.points = const [GeoPointModel(lat: 29.29, lng: 48.07)];
        geocoder.marks = const [];
        final places = build();

        final found = right(
          await places.suggest('gulf road', languageCode: 'en'),
        ).single;
        expect(found.title, 'gulf road');
        expect(
          found.place,
          PinnedPlace.at(const GeoPointEntity(lat: 29.29, lng: 48.07)),
        );
      },
    );

    test('the same words again ask the geocoder nothing; a failure is not '
        'kept', () async {
      geocoder.points = const [GeoPointModel(lat: 29.29, lng: 48.07)];
      geocoder.marks = const [PlacemarkModel(subLocality: 'Salwa')];
      final places = build();

      right(await places.suggest('gulf road', languageCode: 'en'));
      right(await places.suggest('gulf road', languageCode: 'en'));
      expect(geocoder.forwardQueries, ['gulf road, Kuwait']);
      expect(geocoder.reverseLanguages, ['en']);

      geocoder.error = const RequestTimeoutException();
      final failed = await places.suggest('tunis st', languageCode: 'en');
      expect(failed.isLeft(), isTrue);
      geocoder.error = null;
      right(await places.suggest('tunis st', languageCode: 'en'));
      expect(
        geocoder.forwardQueries.where((q) => q == 'tunis st, Kuwait'),
        hasLength(2),
      );
    });

    test(
      'a district answer carries its governorate, in the language asked',
      () async {
        final places = build();
        final en = right(await places.suggest('jahra', languageCode: 'en'));
        expect(en.first.title, 'Jahra');
        expect(en.first.subtitle, 'Jahra Governorate');
        final ar = right(await places.suggest('الجهراء', languageCode: 'ar'));
        expect(ar.first.title, 'الجهراء');
        expect(ar.first.subtitle, 'محافظة الجهراء');
      },
    );

    test('nearest districts first, the typed start in bold', () async {
      final places = build();
      final answers = right(
        await places.suggest('sal', languageCode: 'en', near: pin),
      );
      final titles = answers.map((answer) => answer.title).toList();
      expect(titles.first, 'Salmiya');
      expect(answers.first.titleMatches, const [TextMatch(0, 3)]);
      final distances = [for (final a in answers) a.distanceMeters!];
      expect(distances, [...distances]..sort());
    });

    test('nothing matched and every source failed: the failure', () async {
      geocoder.error = const NoInternetConnectionException();
      final places = build();

      final result = await places.suggest('zzzz', languageCode: 'en');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected a failure'),
      );
    });
  });

  group('locate', () {
    test(
      'an answer with its point needs no request and ends the session',
      () async {
        final places = build(withGoogle: true);
        const area = PlaceSuggestion(
          id: 'area:salwa',
          title: 'Salwa',
          location: GeoPointEntity(lat: 29.29, lng: 48.07),
          source: PlaceSource.area,
        );

        final spot = right(await places.locate(area, languageCode: 'en'));

        expect(spot.location, area.location);
        expect(spot.title, 'Salwa');
        // A whole district: the map shows its streets.
        expect(spot.isArea, isTrue);
        expect(google.detailsAsked, isEmpty);
        expect(google.sessionsEnded, 1);
      },
    );

    test("a Google answer's point is looked up", () async {
      final places = build(withGoogle: true);
      const marina = PlaceSuggestion(
        id: 'p1',
        title: 'Marina Mall',
        subtitle: 'Salmiya',
        source: PlaceSource.google,
      );

      final spot = right(await places.locate(marina, languageCode: 'en'));

      expect(google.detailsAsked, ['p1']);
      expect(
        spot,
        const PlaceSpot(
          location: GeoPointEntity(lat: 29.33, lng: 48.07),
          title: 'Marina Mall',
        ),
      );
    });
  });

  group('delivery areas', () {
    test('every district, A to Z in the language asked, ready to pick', () {
      final places = build();
      final known = const KnownAreasLocalDataSourceImpl().areas();

      final en = right(places.deliveryAreas(languageCode: 'en'));
      expect(en, hasLength(known.length));
      expect(en.first.title, 'Abu Halifa');
      expect(en.last.title, 'Yarmouk');
      for (final area in en) {
        expect(area.source, PlaceSource.area);
        expect(area.location, isNotNull);
        expect(area.id, startsWith('area:'));
      }

      final ar = right(places.deliveryAreas(languageCode: 'ar'));
      final titles = [for (final area in ar) area.title];
      expect(titles.first, 'أبو حليفة');
      // The article set aside: "العديلية" among the ع's, after "شرق".
      expect(titles.indexOf('العديلية'), greaterThan(titles.indexOf('شرق')));
      expect(titles.indexOf('العديلية'), lessThan(titles.indexOf('الفحيحيل')));
    });

    test('each over its governorate, and how far it is once the map is '
        'known — still A to Z', () {
      final places = build();
      final unknown = right(places.deliveryAreas(languageCode: 'en'));
      expect(unknown.map((area) => area.distanceMeters), everyElement(isNull));

      final near = right(places.deliveryAreas(languageCode: 'en', near: pin));
      expect(near.first.title, 'Abu Halifa');
      final salmiya = near.firstWhere((area) => area.title == 'Salmiya');
      expect(salmiya.subtitle, 'Hawalli Governorate');
      expect(salmiya.distanceMeters, 0);
      for (final area in near) {
        expect(area.subtitle, endsWith('Governorate'), reason: area.title);
        expect(area.distanceMeters, isNotNull, reason: area.title);
      }
      final ar = right(places.deliveryAreas(languageCode: 'ar', near: pin));
      expect(
        ar.firstWhere((area) => area.title == 'السالمية').subtitle,
        'محافظة حولي',
      );
    });
  });

  test('ending a search ends the Google session', () {
    final places = build(withGoogle: true);
    expect(places.endSearch().isRight(), isTrue);
    expect(google.sessionsEnded, 1);
  });
}
