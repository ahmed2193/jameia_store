// Google Places API (New) for the address search: what each call sends
// (Kuwait only, the field masks, one session token per search), and how the
// replies are read.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/network/api_headers.dart';
import 'package:hero_mart/src/core/network/external_api_consumer.dart';
import 'package:hero_mart/src/core/network/external_end_points.dart';
import 'package:hero_mart/src/features/address/data/datasources/places_remote_data_source.dart';
import 'package:hero_mart/src/features/address/data/models/geo_point_model.dart';

/// Answers [reply] and records every request.
class _RecordingApi implements ExternalApiConsumer {
  Object? reply;
  final List<
    ({
      String method,
      String url,
      Object? body,
      Map<String, dynamic>? query,
      Map<String, String>? headers,
    })
  >
  requests = [];

  @override
  Future<Object?> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    requests.add((
      method: 'GET',
      url: url,
      body: null,
      query: queryParameters,
      headers: headers,
    ));
    return reply;
  }

  @override
  Future<Object?> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    requests.add((
      method: 'POST',
      url: url,
      body: body,
      query: null,
      headers: headers,
    ));
    return reply;
  }
}

void main() {
  late _RecordingApi api;
  late PlacesRemoteDataSourceImpl places;

  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  Map<String, dynamic> prediction(
    String id,
    String name, {
    List<Map<String, int>> matches = const [],
    int? distance,
  }) => {
    'placePrediction': {
      'placeId': id,
      'text': {'text': '$name, Kuwait'},
      'structuredFormat': {
        'mainText': {'text': name, 'matches': matches},
        'secondaryText': {'text': 'Kuwait'},
      },
      'distanceMeters': ?distance,
    },
  };

  setUp(() {
    api = _RecordingApi()..reply = <String, dynamic>{'suggestions': []};
    places = PlacesRemoteDataSourceImpl(api, apiKey: 'test-key');
  });

  group('autocomplete', () {
    test(
      'asks Kuwait only, near the map, with its key and field mask',
      () async {
        await places.autocomplete(
          'salm',
          languageCode: 'ar',
          near: const GeoPointModel(lat: 29.33, lng: 48.07),
        );

        final request = api.requests.single;
        expect(request.method, 'POST');
        expect(request.url, ExternalEndPoints.googlePlacesAutocomplete);
        expect(request.headers?[ApiHeaders.googleApiKey], 'test-key');
        expect(
          request.headers?[ApiHeaders.googleFieldMask],
          PlacesRemoteDataSourceImpl.autocompleteFieldMask,
        );
        final body = request.body! as Map<String, dynamic>;
        expect(body['input'], 'salm');
        expect(body['languageCode'], 'ar');
        expect(body['regionCode'], 'kw');
        expect(body['includedRegionCodes'], ['kw']);
        expect(body['sessionToken'], matches(uuidV4));
        const point = {'latitude': 29.33, 'longitude': 48.07};
        expect(body['origin'], point);
        expect(body['locationBias'], {
          'circle': {
            'center': point,
            'radius': PlacesRemoteDataSourceImpl.biasRadiusMeters,
          },
        });
      },
    );

    test('without a point it sends no bias and no origin', () async {
      await places.autocomplete('salm', languageCode: 'en');
      final body = api.requests.single.body! as Map<String, dynamic>;
      expect(body.containsKey('locationBias'), isFalse);
      expect(body.containsKey('origin'), isFalse);
    });

    test('reads the place answers; query answers and broken rows are '
        'skipped', () async {
      api.reply = <String, dynamic>{
        'suggestions': [
          prediction(
            'p1',
            'Salmiya',
            matches: [
              {'endOffset': 4},
            ],
            distance: 1200,
          ),
          {
            'queryPrediction': {
              'text': {'text': 'salmiya restaurants'},
            },
          },
          {
            'placePrediction': {'placeId': 'p2'}, // no name
          },
          prediction('p3', 'Salwa'),
        ],
      };

      final answers = await places.autocomplete('sal', languageCode: 'en');

      expect(answers.map((answer) => answer.placeId), ['p1', 'p3']);
      final first = answers.first;
      expect(first.mainText, 'Salmiya');
      expect(first.secondaryText, 'Kuwait');
      expect(first.mainMatches, [(start: 0, end: 4)]);
      expect(first.distanceMeters, 1200);
      expect(answers.last.distanceMeters, isNull);
    });

    test('a reply that is not an object is a parsing error', () async {
      api.reply = 'oops';
      await expectLater(
        places.autocomplete('sal', languageCode: 'en'),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('the search session', () {
    test(
      'keystrokes share a token; the look-up sends it and ends it',
      () async {
        await places.autocomplete('sa', languageCode: 'en');
        await places.autocomplete('sal', languageCode: 'en');
        final first = (api.requests[0].body! as Map)['sessionToken'];
        expect((api.requests[1].body! as Map)['sessionToken'], first);

        api.reply = <String, dynamic>{
          'location': {'latitude': 29.33, 'longitude': 48.07},
          'shortFormattedAddress': 'Salmiya',
        };
        await places.details('p1', languageCode: 'en');
        expect(api.requests[2].query?['sessionToken'], first);

        api.reply = <String, dynamic>{'suggestions': []};
        await places.autocomplete('h', languageCode: 'en');
        expect((api.requests[3].body! as Map)['sessionToken'], isNot(first));
      },
    );

    test('a search left without a pick starts a new session', () async {
      await places.autocomplete('sa', languageCode: 'en');
      places.endSession();
      await places.autocomplete('sa', languageCode: 'en');
      expect(
        (api.requests[0].body! as Map)['sessionToken'],
        isNot((api.requests[1].body! as Map)['sessionToken']),
      );
    });
  });

  group('details', () {
    test('asks for the point only and reads it', () async {
      api.reply = <String, dynamic>{
        'location': {'latitude': 29.33, 'longitude': 48.07},
      };

      final place = await places.details('ChIJ/x', languageCode: 'ar');

      final request = api.requests.single;
      expect(request.method, 'GET');
      expect(request.url, ExternalEndPoints.googlePlace('ChIJ/x'));
      expect(request.url, endsWith('/places/ChIJ%2Fx'));
      expect(request.headers?[ApiHeaders.googleFieldMask], 'location');
      expect(request.query?['languageCode'], 'ar');
      expect(request.query?['regionCode'], 'kw');
      expect(request.query?.containsKey('sessionToken'), isFalse);
      expect(place.location.lat, 29.33);
      expect(place.location.lng, 48.07);
    });

    test('a place without a point is a parsing error', () async {
      api.reply = <String, dynamic>{'shortFormattedAddress': 'Salmiya'};
      await expectLater(
        places.details('p1', languageCode: 'en'),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}
