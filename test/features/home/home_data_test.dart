// Home remote datasource (through the real DioConsumer on a scripted
// transport), the cache datasource (the live fixtures parse back, one copy
// per identity), local popup stamps, and the repository: entities, the
// cache-then-network read, and the failure mapping. The launch read, end to
// end: offline, home paints the identity's saved copy by itself (no tap).
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/core/network/end_points.dart';
import 'package:hero_mart/src/core/storage/cache_key.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/core/storage/local_storage.dart';
import 'package:hero_mart/src/features/home/data/datasources/home_cache_data_source.dart';
import 'package:hero_mart/src/features/home/data/datasources/home_local_data_source.dart';
import 'package:hero_mart/src/features/home/data/datasources/home_remote_data_source.dart';
import 'package:hero_mart/src/features/home/data/models/home_feed_model.dart';
import 'package:hero_mart/src/features/home/data/models/home_init_model.dart';
import 'package:hero_mart/src/features/home/data/repositories/home_repository_impl.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_feed.dart';
import 'package:hero_mart/src/features/home/domain/usecases/check_first_order_welcome_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/mark_home_popups_shown_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/select_due_home_popups_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_bootstrap_usecase.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_feed_usecase.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_launch_prefetch.dart';

import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';
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
  Object? ordersError;
  int homeCalls = 0;

  @override
  Future<RemotePayload<HomeFeedModel>> getHome() async {
    homeCalls++;
    final error = homeError;
    if (error != null) throw error;
    final raw = liveHomeJson();
    return RemotePayload(HomeFeedModel.fromJson(raw), raw);
  }

  @override
  Future<RemotePayload<HomeInitModel>> getInit() async {
    final error = initError;
    if (error != null) throw error;
    final raw = liveInitJson();
    return RemotePayload(HomeInitModel.fromJson(raw), raw);
  }

  @override
  Future<int> countOrders() async {
    final error = ordersError;
    if (error != null) throw error;
    return 2;
  }
}

/// The guest's English home copy, as a load would have saved it.
CacheKey _guestFeedKey() => const CacheKey(
  namespace: HomeCacheDataSourceImpl.feedNamespace,
  language: 'en',
  owner: CacheOwner.guest,
);

HomeCacheDataSourceImpl _cacheOf(
  InMemoryJsonCacheStore store,
  CacheOwner owner,
) => HomeCacheDataSourceImpl(
  CacheSlots(store: store, owner: owner, locale: FakeLocaleProvider('en')),
);

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

      final payload = await dataSource.getHome();
      final home = payload.model;

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, EndPoints.home);
      expect(payload.raw, liveHomeJson(), reason: 'cached exactly as sent');
      expect(home.sections, hasLength(8));
      expect(home.slides, hasLength(3));
      expect(home.categories, hasLength(38));
      expect(home.announcement.enabled, isTrue);
    });

    test('getInit GETs /v1/init and parses the live payload', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(liveInitJson())),
      );

      final init = (await dataSource.getInit()).model;

      expect(adapter.requests.single.path, EndPoints.init);
      expect(init.storeName, 'Hero');
      expect(init.delivery?.zoneName, 'Salmiya & Sharq');
      expect(init.proEnabled, isTrue);
    });

    test(
      'countOrders GETs one row of /v1/orders and reads the total',
      () async {
        final dataSource = build(
          FakeHttpClientAdapter(
            (_, _) => okBody({
              'data': <Object>[],
              'pagination': {
                'total': 0,
                'page': 1,
                'limit': 1,
                'hasMore': false,
              },
            }),
          ),
        );

        final total = await dataSource.countOrders();

        final request = adapter.requests.single;
        expect(request.method, 'GET');
        expect(request.path, EndPoints.orders);
        expect(request.queryParameters, {'page': 1, 'limit': 1});
        expect(total, 0);
      },
    );

    test('countOrders signed out is an UnauthorizedException', () {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 401,
            statusMessage: 'UNAUTHORIZED',
            errorMessage: 'Sign in',
          ),
        ),
      );

      expect(dataSource.countOrders, throwsA(isA<UnauthorizedException>()));
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

  group('HomeCacheDataSourceImpl', () {
    test('the saved live replies parse back with the DTOs', () {
      final cache = _cacheOf(
        InMemoryJsonCacheStore(),
        CacheOwner()..signedOut(),
      );

      expect(cache.feed()!.parse(liveHomeJson()).sections, hasLength(8));
      expect(cache.init()!.parse(liveInitJson()).storeName, 'Hero');
    });

    test('no slot while the identity is unknown', () {
      final cache = _cacheOf(InMemoryJsonCacheStore(), CacheOwner());

      expect(cache.feed(), isNull);
      expect(cache.init(), isNull);
    });

    test("a guest's copy never reaches the signed-in customer", () async {
      final store = InMemoryJsonCacheStore();
      final owner = CacheOwner()..signedOut();
      final cache = _cacheOf(store, owner);
      await cache.feed()!.write(liveHomeJson(), savedAt: savedAtTime);

      owner.signedIn('42');

      expect(await cache.feed()!.read(), isNull);
      owner.signedOut();
      expect(await cache.feed()!.read(), isNotNull);
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
    late InMemoryJsonCacheStore store;
    late HomeRepositoryImpl repository;

    setUp(() {
      remote = _ScriptedRemote();
      storage = _MemoryStorage();
      store = InMemoryJsonCacheStore();
      repository = HomeRepositoryImpl(
        remote,
        HomeLocalDataSourceImpl(storage),
        cache: _cacheOf(store, CacheOwner()..signedOut()),
      );
    });

    test('maps the feed and the bootstrap to entities', () async {
      final feed = await repository.watchHomeFeed().last;
      final bootstrap = await repository.watchBootstrap().last;

      expect(feed.origin, SnapshotOrigin.network);
      expect(feed.data.sections, hasLength(8));
      expect(bootstrap.data.delivery?.zoneName, 'Salmiya & Sharq');
    });

    test(
      'a reply is saved; the next open paints it without a request',
      () async {
        await repository.watchHomeFeed().drain<void>();
        await pumpEventQueue(); // the write is fire and forget

        final reopened = await repository.watchHomeFeed().toList();

        expect(store.writes, 1);
        expect(reopened.single.isFromCache, isTrue);
        expect(reopened.single.data.sections, hasLength(8));
        expect(remote.homeCalls, 1, reason: 'a fresh copy ends the read');
      },
    );

    test('pull to refresh skips the copy', () async {
      await repository.watchHomeFeed().drain<void>();
      await pumpEventQueue();

      final refreshed = await repository
          .watchHomeFeed(forceRefresh: true)
          .toList();

      expect(refreshed.single.origin, SnapshotOrigin.network);
      expect(remote.homeCalls, 2);
    });

    test('offline: a stale copy, then the failure', () async {
      store.seed(
        _guestFeedKey(),
        liveHomeJson(),
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      remote.homeError = const NoInternetConnectionException();

      await expectLater(
        repository.watchHomeFeed(),
        emitsInOrder(<Object>[
          isA<DataSnapshot<HomeFeed>>().having(
            (s) => s.isFromCache,
            'isFromCache',
            isTrue,
          ),
          emitsError(isA<NetworkFailure>()),
        ]),
      );
    });

    test('countOrders maps the count and its failures', () async {
      expect((await repository.countOrders()).getOrElse(() => -1), 2);

      remote.ordersError = const UnauthorizedException('Sign in');
      final signedOut = await repository.countOrders();

      expect(
        signedOut.fold((failure) => failure, (_) => null),
        isA<UnauthorizedFailure>(),
      );
    });

    test('exceptions become their failures', () async {
      remote
        ..homeError = const NoInternetConnectionException()
        ..initError = const ServerException('boom', statusCode: 500);

      await expectLater(
        repository.watchHomeFeed(),
        emitsError(isA<NetworkFailure>()),
      );
      await expectLater(
        repository.watchBootstrap(),
        emitsError(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500),
        ),
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

  // The bug: the splash's home read started before the session restore knew
  // whose app it was, so it had no slot for the identity's copy — offline,
  // home showed its error until a tap read again (by then with the copy).
  group('the launch read, offline, with a saved home', () {
    late _ScriptedRemote remote;
    late InMemoryJsonCacheStore store;
    late CacheOwner owner;
    late HomeRepositoryImpl repository;
    final built = <HomeCubit>[];

    HomeCubit create() {
      final cubit = HomeCubit(
        WatchHomeFeedUseCase(repository),
        const ComposeHomeFeedUseCase(),
        WatchHomeBootstrapUseCase(repository),
        SelectDueHomePopupsUseCase(repository),
        MarkHomePopupsShownUseCase(repository),
        CheckFirstOrderWelcomeUseCase(repository),
      );
      built.add(cubit);
      return cubit;
    }

    setUp(() {
      remote = _ScriptedRemote()
        ..homeError = const NoInternetConnectionException()
        ..initError = const NoInternetConnectionException();
      store = InMemoryJsonCacheStore()
        ..seed(
          _guestFeedKey(),
          liveHomeJson(),
          DateTime.now().subtract(const Duration(hours: 2)),
        );
      owner = CacheOwner(); // the session restore has not answered yet
      repository = HomeRepositoryImpl(
        remote,
        HomeLocalDataSourceImpl(_MemoryStorage()),
        cache: _cacheOf(store, owner),
      );
    });

    tearDown(() async {
      for (final cubit in built) {
        await cubit.close();
      }
      built.clear();
    });

    test('a read before the identity is known misses the copy', () async {
      await expectLater(
        repository.watchHomeFeed(),
        emitsError(isA<NetworkFailure>()),
      );
      expect(store.reads, 0);
    });

    test('the prefetch waits for the identity, then paints its saved copy '
        'by itself — stale, dated, no tap', () async {
      final prefetch = HomeLaunchPrefetch(create, language: () => 'en')
        ..start()
        ..localeReady();
      expect(built, isEmpty);

      owner.signedOut(); // the restore found no session: a guest
      prefetch.identityReady();
      await pumpEventQueue();
      final home = prefetch.adopt();

      expect(home.state.load.phase, LoadPhase.loaded);
      expect(home.state.feed.sections, isNotEmpty);
      expect(home.state.load.freshness.fromCache, isTrue);
      expect(home.state.load.freshness.refreshFailed, isTrue);
      expect(home.state.load.failure, isA<NetworkFailure>());
    });
  });
}
