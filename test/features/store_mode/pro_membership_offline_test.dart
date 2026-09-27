// Pro offline: the programme (public) and the signed-in customer's
// subscription (never a guest's) are kept on the device — "none" too — and
// every server answer (a read, a subscribe, a cancel) replaces the copy. The
// page paints the saved copies marked stale, never shows a paywall before
// it knows the membership, dates a subscribe's answer as the server's, asks
// again once on reconnect, and the brand rows retry when none were shown.
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/datasources/cache_slots.dart';
import 'package:jameia_mart/src/core/data/datasources/catalog_remote_data_source.dart';
import 'package:jameia_mart/src/core/data/models/remote_payload.dart';
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/data_freshness.dart';
import 'package:jameia_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/storage/cache_owner.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/store_mode/data/datasources/pro_membership_cache_data_source.dart';
import 'package:jameia_mart/src/features/store_mode/data/datasources/pro_membership_remote_data_source.dart';
import 'package:jameia_mart/src/features/store_mode/data/models/pro_program_model.dart';
import 'package:jameia_mart/src/features/store_mode/data/models/pro_subscription_model.dart';
import 'package:jameia_mart/src/features/store_mode/data/models/pro_subscription_results.dart';
import 'package:jameia_mart/src/features/store_mode/data/repositories/pro_membership_repository_impl.dart';
import 'package:jameia_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:jameia_mart/src/features/store_mode/domain/repositories/pro_membership_repository.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/cancel_pro_subscription_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_brands_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/subscribe_to_pro_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/watch_pro_program_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/watch_pro_subscription_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_brands_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_membership_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_membership_state.dart';

import '../../core/data/snapshot_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';

/// `GET /v1/subscription-plans` → `results` (the live shape, one plan).
const Map<String, dynamic> _plans = {
  'data': [
    {
      '_id': 'monthly',
      'slug': 'monthly',
      'name': 'Monthly',
      'interval': 'month',
      'intervalCount': 1,
      'price': 2999,
      'sortOrder': 1,
    },
  ],
  'enabled': true,
  'perks': {'freeDelivery': true, 'pointsMultiplier': 2, 'discountPercent': 5},
};

/// A renewing monthly subscription as the server sends it.
const Map<String, dynamic> _renewingJson = {
  '_id': 'sub1',
  'planId': 'monthly',
  'planName': 'Monthly',
  'status': 'active',
  'currentPeriodEnd': '2026-10-17T00:00:00.000Z',
  'cancelAtPeriodEnd': false,
};

/// The same subscription once its renewal was cancelled.
const Map<String, dynamic> _cancelledJson = {
  '_id': 'sub1',
  'planId': 'monthly',
  'planName': 'Monthly',
  'status': 'active',
  'currentPeriodEnd': '2026-10-17T00:00:00.000Z',
  'cancelAtPeriodEnd': true,
};

class _Remote implements ProMembershipRemoteDataSource {
  Object? error;

  /// `results` of the subscription read: `null` = none.
  Object? subscriptionResults = _renewingJson;
  int programReads = 0;
  int subscriptionReads = 0;

  void _failWhenOffline() {
    final current = error;
    if (current != null) throw current;
  }

  @override
  Future<RemotePayload<ProProgramModel>> getProgram() async {
    programReads++;
    _failWhenOffline();
    return RemotePayload(ProProgramModel.fromJson(_plans), _plans);
  }

  @override
  Future<RemotePayload<ProSubscriptionModel?>> getSubscription() async {
    subscriptionReads++;
    _failWhenOffline();
    final results = subscriptionResults;
    return RemotePayload(
      ProSubscriptionResults.parse(results),
      ProSubscriptionResults.keep(results),
    );
  }

  @override
  Future<RemotePayload<ProSubscriptionModel>> subscribe(String planId) async {
    _failWhenOffline();
    return RemotePayload(
      ProSubscriptionModel.fromJson(_renewingJson),
      _renewingJson,
    );
  }

  @override
  Future<RemotePayload<ProSubscriptionModel>> cancel() async {
    _failWhenOffline();
    return RemotePayload(
      ProSubscriptionModel.fromJson(_cancelledJson),
      _cancelledJson,
    );
  }
}

/// The brand rows' catalogue read (unused here).
CatalogRemoteDataSource _catalog() => CatalogRemoteDataSourceImpl(
  DioConsumer(
    Dio()..httpClientAdapter = FakeHttpClientAdapter((_, _) => okBody(null)),
  ),
  FakeLocaleProvider('en'),
);

ProMembershipRepositoryImpl _repository(
  _Remote remote, {
  required CacheOwner owner,
  InMemoryJsonCacheStore? store,
}) => ProMembershipRepositoryImpl(
  remote,
  _catalog(),
  cache: ProMembershipCacheDataSourceImpl(
    CacheSlots(
      store: store ?? InMemoryJsonCacheStore(),
      owner: owner,
      locale: FakeLocaleProvider('en'),
    ),
  ),
);

const ProProgram _program = ProProgram(
  enabled: true,
  plans: [ProPlan(id: 'monthly', name: 'Monthly', priceFils: 2999)],
);

const ProSubscription _member = ProSubscription(
  id: 'sub1',
  planId: 'monthly',
  status: ProSubscriptionStatus.active,
);

/// The Pro reads as the cached reads stream them: the saved copy first
/// (unless forced), then the answer set on the fields.
class _FakeRepository implements ProMembershipRepository {
  Either<Failure, ProProgram> program = const Right(_program);
  Either<Failure, ProSubscription?> subscription = const Right(null);
  Either<Failure, ProSubscription> subscribeReply = const Right(_member);
  ProProgram? savedProgram;
  ProSubscription? savedSubscription;

  /// The `forceRefresh` of every programme read, in order.
  final List<bool> forced = [];

  @override
  Future<Either<Failure, ProProgram>> getProgram() async => program;

  @override
  Stream<DataSnapshot<ProProgram>> watchProgram({bool forceRefresh = false}) {
    forced.add(forceRefresh);
    return networkRead(getProgram(), saved: forceRefresh ? null : savedProgram);
  }

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() async =>
      subscription;

  @override
  Stream<DataSnapshot<ProSubscription?>> watchSubscription({
    bool forceRefresh = false,
  }) => networkRead(
    getSubscription(),
    saved: forceRefresh ? null : savedSubscription,
  );

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) async =>
      subscribeReply;

  @override
  Future<Either<Failure, ProSubscription>> cancel() async =>
      const Left(NetworkFailure());

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async =>
      const Right(<BrandEntity>[]);
}

ProMembershipCubit _cubit(
  ProMembershipRepository repository, {
  DateTime Function()? now,
}) => ProMembershipCubit(
  WatchProProgramUseCase(repository),
  WatchProSubscriptionUseCase(repository),
  SubscribeToProUseCase(repository),
  CancelProSubscriptionUseCase(repository),
  now: now ?? DateTime.now,
);

/// Answers every brands read with [reply], counting them.
class _BrandsUseCase implements GetProBrandsUseCase {
  Either<Failure, List<BrandEntity>> reply = const Left(NetworkFailure());
  int calls = 0;

  @override
  Future<Either<Failure, List<BrandEntity>>> call(NoParams params) async {
    calls++;
    return reply;
  }
}

void main() {
  group('the device copy', () {
    test('the programme and the subscription paint from it', () async {
      final remote = _Remote();
      final repository = _repository(
        remote,
        owner: CacheOwner()..signedIn('c1'),
      );
      await repository.watchProgram().drain<void>();
      await repository.watchSubscription().drain<void>();
      await pumpEventQueue();
      remote.error = const NoInternetConnectionException();

      final program = await repository.watchProgram().toList();
      final subscription = await repository.watchSubscription().toList();

      expect(program.single.isFromCache, isTrue);
      expect(program.single.data.plans.single.id, 'monthly');
      expect(subscription.single.isFromCache, isTrue);
      expect(subscription.single.data?.id, 'sub1');
      expect(remote.programReads, 1, reason: 'a fresh copy ends the read');
      expect(remote.subscriptionReads, 1);
    });

    test('"no subscription" is kept too', () async {
      final remote = _Remote()..subscriptionResults = null;
      final repository = _repository(
        remote,
        owner: CacheOwner()..signedIn('c1'),
      );
      await repository.watchSubscription().drain<void>();
      await pumpEventQueue();
      remote.error = const NoInternetConnectionException();

      final copy = await repository.watchSubscription().toList();

      expect(copy.single.isFromCache, isTrue);
      expect(copy.single.data, isNull);
    });

    test(
      'a guest: the programme is kept, nothing about a membership',
      () async {
        final store = InMemoryJsonCacheStore();
        final repository = _repository(
          _Remote(),
          owner: CacheOwner()..signedOut(),
          store: store,
        );

        await repository.watchProgram().drain<void>();
        await repository.watchSubscription().drain<void>();
        await pumpEventQueue();

        expect(
          [for (final entry in store.entries.values) entry.$1.namespace],
          [ProMembershipCacheDataSourceImpl.programNamespace],
        );
      },
    );

    test('every server answer becomes the copy: a read, a subscribe, a '
        'cancel', () async {
      final remote = _Remote()..subscriptionResults = null;
      final repository = _repository(
        remote,
        owner: CacheOwner()..signedIn('c1'),
      );
      Future<ProSubscription?> saved() async {
        await pumpEventQueue();
        final reads = remote.subscriptionReads;
        final copy = await repository.watchSubscription().first;
        expect(copy.isFromCache, isTrue);
        expect(remote.subscriptionReads, reads, reason: 'fresh: no request');
        return copy.data;
      }

      await repository.getSubscription(); // the app-global status's read
      expect(await saved(), isNull);

      await repository.subscribe('monthly');
      expect((await saved())?.cancelAtPeriodEnd, isFalse);

      await repository.cancel();
      expect((await saved())?.cancelAtPeriodEnd, isTrue);
    });
  });

  group('ProMembershipCubit', () {
    test('offline with both copies saved: the page, marked stale', () async {
      final repository = _FakeRepository()
        ..savedProgram = _program
        ..savedSubscription = _member
        ..program = const Left(NetworkFailure())
        ..subscription = const Left(NetworkFailure());
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.status, ProMembershipStatus.loaded);
      expect(cubit.state.isMember, isTrue);
      expect(cubit.state.freshness.isStale, isTrue);
      expect(cubit.state.freshness.fetchedAt, savedSnapshotAt);
      expect(cubit.state.isMembershipConfirmed, isFalse);
      await cubit.close();
    });

    test('a saved programme alone is never a paywall: the membership is '
        'unknown', () async {
      final repository = _FakeRepository()
        ..savedProgram = _program
        ..program = const Left(NetworkFailure())
        ..subscription = const Left(NetworkFailure());
      final cubit = _cubit(repository);
      final statuses = <ProMembershipStatus>[];
      final listening = cubit.stream.listen(
        (state) => statuses.add(state.status),
      );

      await cubit.load();
      await pumpEventQueue();

      expect(statuses, isNot(contains(ProMembershipStatus.loaded)));
      expect(cubit.state.status, ProMembershipStatus.error);
      expect(cubit.state.failure, isA<NetworkFailure>());
      await listening.cancel();
      await cubit.close();
    });

    test('the saved membership shows first, unconfirmed; the server answer '
        'confirms it', () async {
      final repository = _FakeRepository()
        ..savedProgram = _program
        ..savedSubscription = _member
        ..subscription = const Right(_member);
      final cubit = _cubit(repository);
      final confirmed = <bool>[];
      final listening = cubit.stream
          .where((state) => state.isLoaded)
          .listen((state) => confirmed.add(state.isMembershipConfirmed));

      await cubit.load();
      await pumpEventQueue();

      expect(confirmed.first, isFalse);
      expect(confirmed.last, isTrue);
      expect(cubit.state.freshness.isStale, isFalse);
      await listening.cancel();
      await cubit.close();
    });

    test('reconnect refreshes a saved page once', () async {
      final repository = _FakeRepository()
        ..savedProgram = _program
        ..savedSubscription = _member
        ..program = const Left(NetworkFailure())
        ..subscription = const Left(NetworkFailure());
      final cubit = _cubit(repository);
      await cubit.load();

      repository
        ..program = const Right(_program)
        ..subscription = const Right(_member);
      await Future.wait([cubit.onReconnected(), cubit.onReconnected()]);

      expect(repository.forced, [false, true]);
      expect(cubit.state.freshness.isStale, isFalse);
      expect(cubit.state.isMembershipConfirmed, isTrue);
      await cubit.close();
    });

    test('a page the server just answered is not asked again', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load();

      await cubit.onReconnected();

      expect(repository.forced, [false]);
      await cubit.close();
    });

    test("a subscribe's answer is the server's, dated when it came", () async {
      final at = DateTime.utc(2026, 9, 27, 15);
      final repository = _FakeRepository();
      final cubit = _cubit(repository, now: () => at);
      await cubit.load();

      await cubit.subscribe('monthly');

      expect(cubit.state.subscriptionFreshness, DataFreshness(fetchedAt: at));
      expect(cubit.state.isMembershipConfirmed, isTrue);
      await cubit.close();
    });

    test('a failed subscribe is the customer\'s action; a failed reload is '
        'not', () async {
      final repository = _FakeRepository()
        ..subscribeReply = const Left(NetworkFailure());
      final cubit = _cubit(repository);
      await cubit.load();
      final failed = <ProMembershipState>[];
      final listening = cubit.stream
          .where((state) => state.failure != null)
          .listen(failed.add);

      await cubit.subscribe('monthly');
      repository.program = const Left(NetworkFailure());
      await cubit.refresh();
      await pumpEventQueue();

      expect([for (final state in failed) state.actionFailed], [true, false]);
      await listening.cancel();
      await cubit.close();
    });
  });

  group('ProBrandsCubit.onReconnected', () {
    test('asks again only while no brand could be shown', () async {
      final brands = _BrandsUseCase();
      final cubit = ProBrandsCubit(brands);
      await cubit.load();
      expect(cubit.state.brands, isEmpty);

      brands.reply = const Right([
        BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai'),
      ]);
      await cubit.onReconnected();
      expect(cubit.state.brands, hasLength(1));

      await cubit.onReconnected();
      expect(brands.calls, 2, reason: 'brands on screen: nothing to ask');
      await cubit.close();
    });
  });
}
