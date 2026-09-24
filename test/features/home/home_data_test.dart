// Home remote datasource (through the real DioConsumer on a scripted
// transport), local popup stamps, and the repository's failure mapping.
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/core/storage/local_storage.dart';
import 'package:jameia_mart/src/features/home/data/datasources/home_local_data_source.dart';
import 'package:jameia_mart/src/features/home/data/datasources/home_remote_data_source.dart';
import 'package:jameia_mart/src/features/home/data/models/home_feed_model.dart';
import 'package:jameia_mart/src/features/home/data/models/home_init_model.dart';
import 'package:jameia_mart/src/features/home/data/repositories/home_repository_impl.dart';

import '../../core/network/network_test_fakes.dart';
import 'home_test_fakes.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = <String, Object>{};
  bool failWrites = false;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<bool> setBool(String key, {required bool value}) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
}

class _ScriptedRemote implements HomeRemoteDataSource {
  Object? homeError;
  Object? initError;

  @override
  Future<HomeFeedModel> getHome() async {
    final error = homeError;
    if (error != null) throw error;
    return HomeFeedModel.fromJson(liveHomeJson());
  }

  @override
  Future<HomeInitModel> getInit() async {
    final error = initError;
    if (error != null) throw error;
    return HomeInitModel.fromJson(liveInitJson());
  }
}

void main() {
  group('HomeRemoteDataSourceImpl', () {
    late FakeHttpClientAdapter adapter;

    HomeRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return HomeRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );
    }

    test('getHome GETs /v1/home and parses the live payload', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(liveHomeJson())),
      );

      final home = await dataSource.getHome();

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, EndPoints.home);
      expect(home.sections, hasLength(8));
      expect(home.slides, hasLength(3));
      expect(home.categories, hasLength(38));
      expect(home.announcement.enabled, isTrue);
    });

    test('getInit GETs /v1/init and parses the live payload', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(liveInitJson())),
      );

      final init = await dataSource.getInit();

      expect(adapter.requests.single.path, EndPoints.init);
      expect(init.storeName, 'Jm3eia');
      expect(init.delivery?.zoneName, 'Salmiya & Sharq');
      expect(init.proEnabled, isTrue);
    });

    test('a non-object payload is a ParsingException', () {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody('nope')));

      expect(dataSource.getHome, throwsA(isA<ParsingException>()));
    });

    test('a 503 is a ServerException', () {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 503,
            statusMessage: 'SERVICE_UNAVAILABLE',
            errorMessage: 'Down for maintenance',
          ),
        ),
      );

      expect(dataSource.getHome, throwsA(isA<ServerException>()));
    });
  });

  group('HomeLocalDataSourceImpl', () {
    test('stamps are stored per popup id', () async {
      final storage = _MemoryStorage();
      final local = HomeLocalDataSourceImpl(storage);

      expect(local.popupShownDay('p1'), isNull);
      await local.savePopupShownDay('p1', '2026-09-17');

      expect(local.popupShownDay('p1'), '2026-09-17');
      expect(local.popupShownDay('p2'), isNull);
    });

    test('a refused write is a CacheException', () {
      final local = HomeLocalDataSourceImpl(
        _MemoryStorage()..failWrites = true,
      );

      expect(
        () => local.savePopupShownDay('p1', '2026-09-17'),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('HomeRepositoryImpl', () {
    late _ScriptedRemote remote;
    late _MemoryStorage storage;
    late HomeRepositoryImpl repository;

    setUp(() {
      remote = _ScriptedRemote();
      storage = _MemoryStorage();
      repository = HomeRepositoryImpl(remote, HomeLocalDataSourceImpl(storage));
    });

    test('maps the feed and the bootstrap to entities', () async {
      final feed = await repository.getHomeFeed();
      final bootstrap = await repository.getBootstrap();

      expect(
        feed.getOrElse(() => throw StateError('left')).sections,
        hasLength(8),
      );
      expect(
        bootstrap.getOrElse(() => throw StateError('left')).delivery?.zoneName,
        'Salmiya & Sharq',
      );
    });

    test('exceptions become their failures', () async {
      remote
        ..homeError = const NoInternetConnectionException()
        ..initError = const ServerException('boom', statusCode: 500);

      final feed = await repository.getHomeFeed();
      final bootstrap = await repository.getBootstrap();

      expect(
        feed.swap().getOrElse(() => throw StateError('right')),
        isA<NetworkFailure>(),
      );
      expect(
        bootstrap.swap().getOrElse(() => throw StateError('right')),
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500),
      );
    });

    test(
      'popup stamps round-trip; a refused write is a CacheFailure',
      () async {
        expect(
          await repository.savePopupShownDay('p1', '2026-09-17'),
          const Right<Failure, Unit>(unit),
        );
        expect(
          repository.popupShownDay('p1'),
          const Right<Failure, String?>('2026-09-17'),
        );

        storage.failWrites = true;
        final refused = await repository.savePopupShownDay('p2', '2026-09-17');

        expect(
          refused.swap().getOrElse(() => throw StateError('right')),
          isA<CacheFailure>(),
        );
      },
    );
  });
}
