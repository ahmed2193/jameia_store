import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/network/api_consumer.dart';
import 'package:hero_mart/src/core/network/api_headers.dart';
import 'package:hero_mart/src/core/network/end_points.dart';
import 'package:hero_mart/src/core/network/external_api_consumer.dart';
import 'package:hero_mart/src/core/network/external_end_points.dart';
import 'package:hero_mart/src/features/orders/data/datasources/courier_store_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/fallback_road_route_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/google_road_route_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/osrm_road_route_data_source.dart';
import 'package:hero_mart/src/features/orders/data/datasources/road_route_data_source.dart';
import 'package:hero_mart/src/features/orders/data/mappers/encoded_polyline.dart';
import 'package:hero_mart/src/features/orders/data/models/courier_point_model.dart';
import 'package:hero_mart/src/features/orders/data/models/road_route_model.dart';

import '../../core/network/network_test_fakes.dart';

/// The encoder the decoder undoes (Google's algorithm), to build test roads.
String encode(List<List<double>> points, {int precision = 5}) {
  var factor = 1;
  for (var i = 0; i < precision; i++) {
    factor *= 10;
  }
  final out = StringBuffer();
  var lastLat = 0;
  var lastLng = 0;
  void value(int delta) {
    var v = delta < 0 ? ~(delta << 1) : delta << 1;
    while (v >= 0x20) {
      out.writeCharCode((0x20 | (v & 0x1F)) + 63);
      v >>= 5;
    }
    out.writeCharCode(v + 63);
  }

  for (final point in points) {
    final lat = (point[0] * factor).round();
    final lng = (point[1] * factor).round();
    value(lat - lastLat);
    value(lng - lastLng);
    lastLat = lat;
    lastLng = lng;
  }
  return out.toString();
}

/// Answers every call with [reply] (or throws [error]) and records it.
class FakeExternalApi implements ExternalApiConsumer {
  FakeExternalApi({this.reply, this.error});

  Object? reply;
  AppException? error;
  final List<
    ({
      String url,
      Object? body,
      Map<String, dynamic>? query,
      Map<String, String>? headers,
      Duration? timeout,
    })
  >
  calls = [];

  @override
  Future<Object?> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    calls.add((
      url: url,
      body: null,
      query: queryParameters,
      headers: headers,
      timeout: timeout,
    ));
    if (error != null) throw error!;
    return reply;
  }

  @override
  Future<Object?> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    calls.add((
      url: url,
      body: body,
      query: null,
      headers: headers,
      timeout: timeout,
    ));
    if (error != null) throw error!;
    return reply;
  }
}

class FakeApi implements ApiConsumer {
  FakeApi(this.answer);

  Future<dynamic> Function(String path) answer;
  int calls = 0;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    calls++;
    return answer(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoads implements RoadRouteDataSource {
  FakeRoads(this.answer);

  Future<RoadRouteModel> Function() answer;
  int calls = 0;
  final List<Duration?> timeouts = [];

  @override
  Future<RoadRouteModel> route(
    List<GeoPointEntity> stops, {
    Duration? timeout,
  }) {
    calls++;
    timeouts.add(timeout);
    return answer();
  }
}

/// Never answers; records whether Dio told it the request was cancelled.
class HangingHttpClientAdapter implements HttpClientAdapter {
  bool cancelled = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    unawaited(cancelFuture?.then((_) => cancelled = true));
    return Completer<ResponseBody>().future;
  }

  @override
  void close({bool force = false}) {}
}

const List<GeoPointEntity> stops = [
  GeoPointEntity(lat: 29.30, lng: 48.00),
  GeoPointEntity(lat: 29.31, lng: 48.01),
  GeoPointEntity(lat: 29.32, lng: 48.02),
];

final RoadRouteModel oneLeg = RoadRouteModel(
  legs: const [
    RoadLegModel(
      points: [
        CourierPointModel(lat: 1, lng: 1),
        CourierPointModel(lat: 2, lng: 2),
      ],
    ),
  ],
  source: RoadRouteModel.osmSource,
);

void main() {
  group('EncodedPolyline', () {
    test("decodes Google's documented example", () {
      final points = EncodedPolyline.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      expect(points.map((p) => [p.lat, p.lng]), [
        [38.5, -120.2],
        [40.7, -120.95],
        [43.252, -126.453],
      ]);
    });

    test('decodes polyline6 at 6 decimals', () {
      final road = [
        [29.337512, 48.069701],
        [29.331023, 48.061044],
      ];

      final points = EncodedPolyline.decode(
        encode(road, precision: 6),
        precision: EncodedPolyline.osrmPrecision,
      );

      expect(points.first.lat, closeTo(29.337512, 1e-9));
      expect(points.last.lng, closeTo(48.061044, 1e-9));
    });

    test('an empty string is no points; a cut-off one throws', () {
      expect(EncodedPolyline.decode(''), isEmpty);
      expect(
        () => EncodedPolyline.decode('_p~iF~ps|U_'),
        throwsFormatException,
      );
    });
  });

  group('RoadRouteModel.fromGoogleJson', () {
    Map<String, dynamic> leg(
      List<List<double>> road, {
      List<Object>? traffic,
    }) => {
      'distanceMeters': 1000,
      'duration': '100s',
      'polyline': {'encodedPolyline': encode(road)},
      if (traffic != null) 'travelAdvisory': {'speedReadingIntervals': traffic},
    };

    test('reads each leg, paced from its average and its traffic', () {
      final route = RoadRouteModel.fromGoogleJson({
        'routes': [
          {
            'legs': [
              leg([
                [29.30, 48.00],
                [29.31, 48.01],
              ]),
              leg(
                [
                  [29.31, 48.01],
                  [29.32, 48.02],
                  [29.33, 48.03],
                ],
                traffic: [
                  {
                    'startPolylinePointIndex': 0,
                    'endPolylinePointIndex': 1,
                    'speed': 'NORMAL',
                  },
                  {
                    'startPolylinePointIndex': 1,
                    'endPolylinePointIndex': 2,
                    'speed': 'TRAFFIC_JAM',
                  },
                ],
              ),
            ],
          },
        ],
      });

      expect(route.source, RoadRouteModel.googleSource);
      expect(route.legs, hasLength(2));
      expect(route.legs.last.points, hasLength(3));
      // 1000 m / 100 s = 10 m/s; free-flowing a little over, jammed far under;
      // a stretch no interval covers keeps the average.
      expect(route.legs.last.paces.first, closeTo(11, 1e-9));
      expect(route.legs.last.paces.last, closeTo(2.5, 1e-9));
      expect(route.legs.first.paces, [10]);
    });

    test('a reply without legs is no route', () {
      expect(
        () => RoadRouteModel.fromGoogleJson({'routes': <Object>[]}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('RoadRouteModel.fromOsrmJson', () {
    final road = [
      [29.300, 48.000],
      [29.305, 48.000],
      [29.310, 48.000],
      [29.310, 48.005],
      [29.310, 48.010],
    ];

    Map<String, dynamic> reply({bool annotated = true}) => {
      'code': 'Ok',
      'waypoints': [
        {
          'location': [48.000, 29.300],
        },
        {
          'location': [48.0001, 29.3101],
        },
        {
          'location': [48.010, 29.310],
        },
      ],
      'routes': [
        {
          'geometry': encode(road, precision: 6),
          'legs': [
            {
              if (annotated)
                'annotation': {
                  'distance': [500, 500],
                  'duration': [50, 100],
                },
            },
            {
              if (annotated)
                'annotation': {
                  'distance': [480, 480],
                  'duration': [40, 40],
                },
            },
          ],
        },
      ],
    };

    test('splits the road at the inner waypoint, paced per stretch', () {
      final route = RoadRouteModel.fromOsrmJson(reply());

      expect(route.source, RoadRouteModel.osmSource);
      expect(route.legs.first.points, hasLength(3));
      expect(route.legs.last.points, hasLength(3));
      expect(route.legs.first.points.last.lat, closeTo(29.31, 1e-9));
      expect(route.legs.first.paces, [10, 5]);
      expect(route.legs.last.paces, [12, 12]);
    });

    test('without annotations the legs have no paces', () {
      final route = RoadRouteModel.fromOsrmJson(reply(annotated: false));

      expect(route.legs, hasLength(2));
      expect(route.legs.first.paces, isEmpty);
    });

    test('a route without a geometry is no route', () {
      expect(
        () => RoadRouteModel.fromOsrmJson({
          'routes': [<String, dynamic>{}],
        }),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('road services', () {
    test('Google: posts the stops with the key and the field mask', () async {
      final api = FakeExternalApi(
        reply: {
          'routes': [
            {
              'legs': [
                {
                  'polyline': {
                    'encodedPolyline': encode([
                      [29.30, 48.00],
                      [29.31, 48.01],
                    ]),
                  },
                },
              ],
            },
          ],
        },
      );

      final route = await GoogleRoadRouteDataSource(
        api,
        apiKey: 'key',
      ).route(stops);

      final call = api.calls.single;
      expect(call.url, ExternalEndPoints.googleComputeRoutes);
      expect(call.headers?[ApiHeaders.googleApiKey], 'key');
      expect(
        call.headers?[ApiHeaders.googleFieldMask],
        GoogleRoadRouteDataSource.fieldMask,
      );
      final body = call.body! as Map<String, dynamic>;
      expect(body['intermediates'], hasLength(1));
      expect(body['travelMode'], 'DRIVE');
      expect(route.legs.single.paces, isEmpty);
    });

    test('OSRM: asks lng,lat pairs for the full polyline6 road', () async {
      final api = FakeExternalApi(error: const NotFoundException('x'));

      await expectLater(
        OsrmRoadRouteDataSource(api).route(stops),
        throwsA(isA<NotFoundException>()),
      );

      final call = api.calls.single;
      expect(
        call.url,
        ExternalEndPoints.osrmRoute(
          '48.000000,29.300000;48.010000,29.310000;48.020000,29.320000',
        ),
      );
      expect(call.query, {
        'overview': 'full',
        'geometries': 'polyline6',
        'annotations': 'distance,duration',
      });
    });

    test('OSRM: a reply that is not Ok is no route', () {
      final api = FakeExternalApi(reply: {'code': 'NoRoute'});

      expect(
        OsrmRoadRouteDataSource(api).route(stops),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('the fallback takes the first service that answers', () async {
      final failing = FakeRoads(() async => throw const ServerException('x'));
      final working = FakeRoads(() async => oneLeg);

      final route = await FallbackRoadRouteDataSource([failing, working])
          .route(stops);

      expect(route, same(oneLeg));
      expect(failing.calls, 1);
    });

    test('a service slower than its budget counts as failed', () async {
      final hanging = FakeRoads(() => Completer<RoadRouteModel>().future);
      final working = FakeRoads(() async => oneLeg);

      final route = await FallbackRoadRouteDataSource([
        hanging,
        working,
      ], budget: const Duration(milliseconds: 10)).route(stops);

      expect(route, same(oneLeg));
      expect(hanging.calls, 1);
    });

    test('the fallback hands its budget down to every service', () async {
      const budget = Duration(milliseconds: 10);
      final failing = FakeRoads(() async => throw const ServerException('x'));
      final working = FakeRoads(() async => oneLeg);

      await FallbackRoadRouteDataSource([
        failing,
        working,
      ], budget: budget).route(stops);

      expect(failing.timeouts, [budget]);
      expect(working.timeouts, [budget]);
    });

    test('a tighter deadline from the caller wins over the budget', () async {
      const deadline = Duration(milliseconds: 5);
      final working = FakeRoads(() async => oneLeg);

      await FallbackRoadRouteDataSource([
        working,
      ], budget: const Duration(seconds: 6)).route(stops, timeout: deadline);

      expect(working.timeouts, [deadline]);
    });

    test('Google and OSRM pass the deadline to the client', () async {
      const deadline = Duration(seconds: 3);
      final api = FakeExternalApi(error: const NotFoundException('x'));

      await expectLater(
        GoogleRoadRouteDataSource(
          api,
          apiKey: 'key',
        ).route(stops, timeout: deadline),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        OsrmRoadRouteDataSource(api).route(stops, timeout: deadline),
        throwsA(isA<NotFoundException>()),
      );

      expect(api.calls.map((call) => call.timeout), [deadline, deadline]);
    });

    test('the fallback throws the last failure when none answers', () {
      final source = FallbackRoadRouteDataSource([
        FakeRoads(() async => throw const ServerException('first')),
        FakeRoads(() async => throw const NotFoundException('last')),
      ]);

      expect(source.route(stops), throwsA(isA<NotFoundException>()));
    });
  });

  group('CourierStoreRemoteDataSourceImpl', () {
    Map<String, dynamic> branches() => {
      'data': [
        {'_id': 'b1', 'lat': 29.33, 'lng': 48.07, 'phone': '+96522221111'},
        {'_id': 'b2'},
        {'name': 'no id'},
      ],
    };

    test('finds the branch by id, reading the list once', () async {
      final api = FakeApi((path) async {
        expect(path, EndPoints.deliveryBranches);
        return branches();
      });
      final stores = CourierStoreRemoteDataSourceImpl(api);

      final b1 = await stores.store('b1');
      final b2 = await stores.store('b2');

      expect(b1?.point?.lat, 29.33);
      expect(b1?.phone, '+96522221111');
      expect(b2?.point, isNull);
      expect(await stores.store('missing'), isNull);
      expect(api.calls, 1);
    });

    test('no id asks nothing; a failed read is tried again', () async {
      var fail = true;
      final api = FakeApi((_) async {
        if (fail) throw const NoInternetConnectionException();
        return branches();
      });
      final stores = CourierStoreRemoteDataSourceImpl(api);

      expect(await stores.store(''), isNull);
      await expectLater(
        stores.store('b1'),
        throwsA(isA<NoInternetConnectionException>()),
      );
      fail = false;

      expect((await stores.store('b1'))?.id, 'b1');
      expect(api.calls, 2);
    });
  });

  group('DioExternalApiConsumer', () {
    test(
      'returns the decoded body; an error status is an AppException',
      () async {
        final adapter = FakeHttpClientAdapter(
          (options, call) => ResponseBody.fromString(
            jsonEncode(call == 0 ? {'code': 'Ok'} : {'error': 'denied'}),
            call == 0 ? 200 : 403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
        final api = DioExternalApiConsumer(Dio()..httpClientAdapter = adapter);

        expect(await api.get('https://example.com/a'), {'code': 'Ok'});
        await expectLater(
          api.post('https://example.com/b', body: {'x': 1}),
          throwsA(isA<ForbiddenException>()),
        );
        expect(adapter.requests.last.uri.toString(), 'https://example.com/b');
      },
    );

    test('past its timeout a call is cancelled and times out', () async {
      final adapter = HangingHttpClientAdapter();
      final api = DioExternalApiConsumer(Dio()..httpClientAdapter = adapter);

      await expectLater(
        api.post(
          'https://example.com/slow',
          body: {'x': 1},
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<RequestTimeoutException>()),
      );
      await pumpEventQueue();

      expect(adapter.cancelled, isTrue);
    });
  });
}
