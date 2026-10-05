// Where Hero delivers: Kuwait's OpenStreetMap outline — the boundary file
// jm3eia_mobile ships — checked with jm3eia's own parity cases, the file's
// rules, and how the bundled file is read.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/features/address/data/datasources/service_area_local_data_source.dart';
import 'package:hero_mart/src/features/address/data/models/service_area_model.dart';
import 'package:hero_mart/src/features/address/data/repositories/service_area_repository_impl.dart';
import 'package:hero_mart/src/features/address/domain/entities/service_area.dart';

/// A bundle holding [text] (or nothing), counting its reads.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);

  String? text;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    reads++;
    final body = text;
    if (body == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(utf8.encode(body));
  }
}

/// A boundary file in the shape of the bundled one around [ring]
/// (`[lng, lat]` corners, the first repeated last).
Map<String, dynamic> _file(
  List<List<double>> ring, {
  Object schemaVersion = 1,
  Object? version = '2026-06-01.1',
}) => <String, dynamic>{
  'schemaVersion': schemaVersion,
  'version': ?version,
  'core': <String, dynamic>{
    'type': 'MultiPolygon',
    'coordinates': [
      [ring],
    ],
  },
};

const List<List<double>> _square = [
  [47, 29],
  [48, 29],
  [48, 30],
  [47, 30],
  [47, 29],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServiceArea kuwait;

  setUpAll(() async {
    final read = await ServiceAreaRepositoryImpl(
      ServiceAreaLocalDataSourceImpl(rootBundle),
    ).serviceArea();
    kuwait = read.fold((failure) => fail('no outline: $failure'), (a) => a);
  });

  test('the outline is made once', () async {
    final repository = ServiceAreaRepositoryImpl(
      ServiceAreaLocalDataSourceImpl(rootBundle),
    );
    final first = (await repository.serviceArea()).fold((_) => null, (a) => a);
    final second = (await repository.serviceArea()).fold((_) => null, (a) => a);
    expect(first, isNotNull);
    expect(identical(first, second), isTrue);
  });

  // jm3eia_mobile's docs/api/kuwait_boundary_parity_cases.json: its
  // `insideKuwait` points are inside. Its 20 km buffer is not Hero's (only
  // jm3eia's coverage check turns those towns away), so its `insideBuffer`
  // points are outside here, with its `outside` ones.
  const inside = <String, GeoPointEntity>{
    'Kuwait City': GeoPointEntity(lat: 29.3759, lng: 47.9774),
    'Salmiya': GeoPointEntity(lat: 29.3339, lng: 48.0757),
    'Jahra': GeoPointEntity(lat: 29.3375, lng: 47.6581),
    'Salmi village': GeoPointEntity(lat: 29.0986411, lng: 46.6787785),
    'Salmi admin centre': GeoPointEntity(lat: 29.1476217, lng: 46.7035494),
    'Salmi camps, west': GeoPointEntity(lat: 29.16, lng: 46.9),
    'Salmi camps, middle': GeoPointEntity(lat: 29.22, lng: 47.15),
    'Salmi camps, east': GeoPointEntity(lat: 29.27, lng: 47.4),
    'Salmi, west tip': GeoPointEntity(lat: 29.1, lng: 46.57),
    'Kabd': GeoPointEntity(lat: 29.166, lng: 47.654),
    'Wafra farms': GeoPointEntity(lat: 28.62, lng: 47.95),
    'Wafra, south edge': GeoPointEntity(lat: 28.535, lng: 47.93),
    'Abdali farms': GeoPointEntity(lat: 29.99, lng: 47.73),
    'Sulaibiya farms': GeoPointEntity(lat: 29.27, lng: 47.8),
    'Subiya': GeoPointEntity(lat: 29.6, lng: 48.06),
    'Khiran': GeoPointEntity(lat: 28.66, lng: 48.37),
    'Julaia': GeoPointEntity(lat: 28.86, lng: 48.28),
    'Bnaider, 200 m off shore': GeoPointEntity(lat: 28.8, lng: 48.3),
    'Mutlaa': GeoPointEntity(lat: 29.47, lng: 47.58),
    'Bubiyan island': GeoPointEntity(lat: 29.75, lng: 48.2),
    'Failaka island': GeoPointEntity(lat: 29.44, lng: 48.33),
    'Nuwaiseeb, Kuwaiti side': GeoPointEntity(lat: 28.56, lng: 48.4),
    "Kuwait's waters near shore": GeoPointEntity(lat: 29.3, lng: 48.6),
  };

  const outside = <String, GeoPointEntity>{
    'Saudi desert 5 km west of Salmi': GeoPointEntity(lat: 29.05, lng: 46.6),
    'Saudi desert 15 km west of Salmi': GeoPointEntity(lat: 29.1, lng: 46.4),
    'Saudi desert south of Salmi': GeoPointEntity(lat: 28.95, lng: 46.75),
    'Safwan': GeoPointEntity(lat: 30.114, lng: 47.722),
    'Umm Qasr': GeoPointEntity(lat: 30.034, lng: 47.932),
    'Khafji': GeoPointEntity(lat: 28.43, lng: 48.49),
    'the Abdali road, Iraqi side': GeoPointEntity(lat: 30.09, lng: 47.72),
    'Saudi desert 25 km west of Salmi': GeoPointEntity(lat: 29.1, lng: 46.3),
    'Basra': GeoPointEntity(lat: 30.508, lng: 47.783),
    'Hafar al-Batin': GeoPointEntity(lat: 28.43, lng: 45.97),
    'Riyadh': GeoPointEntity(lat: 24.7136, lng: 46.6753),
    'the Gulf, 35 km off shore': GeoPointEntity(lat: 29.3, lng: 48.95),
    'the open Gulf': GeoPointEntity(lat: 28.9, lng: 49.3),
    'Marrakesh': GeoPointEntity(lat: 31.63, lng: -8.0),
  };

  for (final MapEntry(key: name, value: point) in inside.entries) {
    test('$name is inside', () => expect(kuwait.contains(point), isTrue));
  }
  for (final MapEntry(key: name, value: point) in outside.entries) {
    test('$name is outside', () => expect(kuwait.contains(point), isFalse));
  }

  group('the boundary file', () {
    test('reads [lng, lat] corners, dropping the one that closes a ring', () {
      final model = ServiceAreaModel.fromJson(_file(_square));
      expect(model.version, '2026-06-01.1');
      expect(model.rings.single, hasLength(4));
      expect(model.rings.single.first.lat, 29);
      expect(model.rings.single.first.lng, 47);
    });

    test('another schema is refused', () {
      expect(
        () => ServiceAreaModel.fromJson(_file(_square, schemaVersion: 2)),
        throwsA(isA<ParsingException>()),
      );
    });

    test('no version is refused', () {
      expect(
        () => ServiceAreaModel.fromJson(_file(_square, version: null)),
        throwsA(isA<ParsingException>()),
      );
    });

    test('a bad corner refuses the whole outline', () {
      expect(
        () => ServiceAreaModel.fromJson(
          _file([
            ..._square.take(2),
            [48, 95],
            ..._square.skip(2),
          ]),
        ),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('the read', () {
    test('happens once; pickers asking together share it', () async {
      final bundle = _Bundle(jsonEncode(_file(_square)));
      final source = ServiceAreaLocalDataSourceImpl(bundle);
      final reads = await Future.wait([source.area(), source.area()]);
      await source.area();
      expect(bundle.reads, 1);
      expect(identical(reads.first, reads.last), isTrue);
    });

    test('a missing file is a CacheException, and the next picker tries '
        'again', () async {
      final bundle = _Bundle(null);
      final source = ServiceAreaLocalDataSourceImpl(bundle);
      await expectLater(source.area(), throwsA(isA<CacheException>()));
      bundle.text = jsonEncode(_file(_square));
      final area = await source.area();
      expect(area.rings.single, hasLength(4));
      expect(bundle.reads, 2);
    });

    test('a file that is not JSON is a ParsingException', () async {
      final source = ServiceAreaLocalDataSourceImpl(_Bundle('{not json'));
      await expectLater(source.area(), throwsA(isA<ParsingException>()));
    });
  });

  test('an outline of fewer than three corners holds nothing', () {
    const line = ServiceArea([
      [GeoPointEntity(lat: 29, lng: 47), GeoPointEntity(lat: 30, lng: 48)],
    ]);
    expect(line.contains(const GeoPointEntity(lat: 29.5, lng: 47.5)), isFalse);
  });

  test('a hole cuts its ring out (even-odd)', () {
    const withHole = ServiceArea([
      [
        GeoPointEntity(lat: 29, lng: 47),
        GeoPointEntity(lat: 29, lng: 48),
        GeoPointEntity(lat: 30, lng: 48),
        GeoPointEntity(lat: 30, lng: 47),
      ],
      [
        GeoPointEntity(lat: 29.4, lng: 47.4),
        GeoPointEntity(lat: 29.4, lng: 47.6),
        GeoPointEntity(lat: 29.6, lng: 47.6),
        GeoPointEntity(lat: 29.6, lng: 47.4),
      ],
    ]);
    expect(
      withHole.contains(const GeoPointEntity(lat: 29.2, lng: 47.2)),
      isTrue,
    );
    expect(
      withHole.contains(const GeoPointEntity(lat: 29.5, lng: 47.5)),
      isFalse,
    );
  });
}
