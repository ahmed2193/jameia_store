// Pro membership (what replaced the offline VIP ⇄ Mart store mode): the plan
// maths of the entities (per-month price, best value, "Save N%", the plan the
// page opens on), DTOs fed with the live plans payload, the remote datasource,
// the repository's failure mapping, the paywall's brand rows, and the cubits'
// rules (plan selection, a member's locked tabs, guest, double submit, a
// reload landing during or after a subscribe / cancel, a failed subscription
// read, a stale brands reply).
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/datasources/catalog_remote_data_source.dart';
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/store_mode/data/datasources/pro_membership_remote_data_source.dart';
import 'package:jameia_mart/src/features/store_mode/data/mappers/pro_membership_mapper.dart';
import 'package:jameia_mart/src/features/store_mode/data/models/pro_program_model.dart';
import 'package:jameia_mart/src/features/store_mode/data/models/pro_subscription_model.dart';
import 'package:jameia_mart/src/features/store_mode/data/repositories/pro_membership_repository_impl.dart';
import 'package:jameia_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:jameia_mart/src/features/store_mode/domain/repositories/pro_membership_repository.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/cancel_pro_subscription_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_brands_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_program_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_subscription_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/subscribe_to_pro_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_brands_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_brands_state.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_membership_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_membership_state.dart';

import '../../core/network/network_test_fakes.dart';

/// `results` of `GET /v1/subscription-plans` on the live host (2026-09-17).
const Map<String, dynamic> _livePlans = {
  'data': [
    {
      '_id': '6aa6011a8a2745ca861636d2',
      'slug': 'annual',
      'name': 'Annual',
      'interval': 'year',
      'intervalCount': 1,
      'price': 24999,
      'sortOrder': 2,
    },
    {
      '_id': '6aa6011a8a2745ca861636d1',
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

const Map<String, dynamic> _subscriptionJson = {
  '_id': 'sub1',
  'planId': '6aa6011a8a2745ca861636d1',
  'planName': 'Monthly',
  'interval': 'month',
  'intervalCount': 1,
  'price': 2999,
  'status': 'active',
  'currentPeriodStart': '2026-09-17T00:00:00.000Z',
  'currentPeriodEnd': '2026-10-17T00:00:00.000Z',
  'cancelledAt': null,
  'cancelAtPeriodEnd': false,
};

const _monthly = ProSubscription(
  id: 'sub1',
  planId: 'monthly',
  planName: 'Monthly',
  status: ProSubscriptionStatus.active,
);

/// The live plans as entities: Monthly 2.999 KD, Annual 24.999 KD.
const _monthlyPlan = ProPlan(
  id: 'monthly',
  name: 'Monthly',
  slug: 'monthly',
  priceFils: 2999,
  sortOrder: 1,
);
const _annualPlan = ProPlan(
  id: 'annual',
  name: 'Annual',
  slug: 'annual',
  interval: ProBillingInterval.year,
  priceFils: 24999,
  sortOrder: 2,
);

/// 7.500 KD every 3 months = 2.500 KD / month (dearer than the annual plan).
const _quarterlyPlan = ProPlan(
  id: 'quarterly',
  name: 'Quarterly',
  intervalCount: 3,
  priceFils: 7500,
);

/// An interval the app does not know: never compared per month.
const _oddPlan = ProPlan(
  id: 'odd',
  name: 'Odd',
  interval: ProBillingInterval.other,
  priceFils: 1,
);

const _liveProgram = ProProgram(
  enabled: true,
  perks: ProPerks(freeDelivery: true, pointsMultiplier: 2, discountPercent: 5),
  plans: [_monthlyPlan, _annualPlan],
);

const _almarai = BrandEntity(id: 'b1', slug: 'almarai', name: 'Almarai');
const _kdd = BrandEntity(id: 'b2', slug: 'kdd', name: 'KDD');

class _FakeRepository implements ProMembershipRepository {
  Either<Failure, ProProgram> program = const Right(
    ProProgram(
      enabled: true,
      plans: [ProPlan(id: 'monthly', name: 'Monthly')],
    ),
  );
  Either<Failure, ProSubscription?> subscription = const Right(null);
  final List<Completer<Either<Failure, ProSubscription>>> subscribeCalls = [];
  Either<Failure, ProSubscription> cancelReply = const Right(
    ProSubscription(
      id: 'sub1',
      planId: 'monthly',
      status: ProSubscriptionStatus.active,
      cancelAtPeriodEnd: true,
    ),
  );
  int cancelCalls = 0;

  /// While set, the subscription read waits for it (a reload still in
  /// flight), then answers whatever [subscription] holds.
  Completer<void>? subscriptionGate;

  @override
  Future<Either<Failure, ProProgram>> getProgram() async => program;

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() async {
    await subscriptionGate?.future;
    return subscription;
  }

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) {
    final completer = Completer<Either<Failure, ProSubscription>>();
    subscribeCalls.add(completer);
    return completer.future;
  }

  @override
  Future<Either<Failure, ProSubscription>> cancel() async {
    cancelCalls++;
    return cancelReply;
  }

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async =>
      const Right(<BrandEntity>[]);
}

/// Answers each `call` only when the test completes its [Completer] — the
/// order replies land in is the test's choice.
class _GatedBrandsUseCase implements GetProBrandsUseCase {
  final List<Completer<Either<Failure, List<BrandEntity>>>> calls = [];

  @override
  Future<Either<Failure, List<BrandEntity>>> call(NoParams params) {
    final completer = Completer<Either<Failure, List<BrandEntity>>>();
    calls.add(completer);
    return completer.future;
  }
}

/// The shared catalogue datasource on a scripted transport.
CatalogRemoteDataSource _catalogOn(FakeHttpClientAdapter adapter) =>
    CatalogRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = adapter),
      FakeLocaleProvider('en'),
    );

class _ScriptedRemote implements ProMembershipRemoteDataSource {
  Object? error;

  @override
  Future<ProProgramModel> getProgram() async =>
      ProProgramModel.fromJson(_livePlans);

  @override
  Future<ProSubscriptionModel?> getSubscription() async {
    final current = error;
    if (current != null) throw current;
    return null;
  }

  @override
  Future<ProSubscriptionModel> subscribe(String planId) async =>
      ProSubscriptionModel.fromJson(_subscriptionJson);

  @override
  Future<ProSubscriptionModel> cancel() async =>
      ProSubscriptionModel.fromJson(_subscriptionJson);
}

ProMembershipCubit _cubit(ProMembershipRepository repository) =>
    ProMembershipCubit(
      GetProProgramUseCase(repository),
      GetProSubscriptionUseCase(repository),
      SubscribeToProUseCase(repository),
      CancelProSubscriptionUseCase(repository),
    );

void main() {
  group('ProPlan per-month maths', () {
    test('month x1: one month, billed as charged', () {
      expect(_monthlyPlan.months, 1);
      expect(_monthlyPlan.monthlyPriceFils, 2999);
      expect(_monthlyPlan.monthlyPriceKd, 2.999);
      expect(_monthlyPlan.isMultiMonth, isFalse);
    });

    test('month x3: spread over three months', () {
      expect(_quarterlyPlan.months, 3);
      expect(_quarterlyPlan.monthlyPriceFils, 2500);
      expect(_quarterlyPlan.monthlyPriceKd, 2.5);
      expect(_quarterlyPlan.isMultiMonth, isTrue);
    });

    test('year x1: twelve months, rounded to the fils (website 2.083)', () {
      expect(_annualPlan.months, 12);
      expect(_annualPlan.monthlyPriceFils, 2083);
      expect(_annualPlan.monthlyPriceKd, 2.083);
      expect(_annualPlan.isMultiMonth, isTrue);
    });

    test('an unknown interval cannot be compared per month', () {
      expect(_oddPlan.months, isNull);
      expect(_oddPlan.monthlyPriceFils, isNull);
      expect(_oddPlan.monthlyPriceKd, isNull);
      expect(_oddPlan.isMultiMonth, isFalse);
    });

    test('a non-positive interval count cannot be compared either', () {
      const broken = ProPlan(id: 'x', name: 'X', intervalCount: 0);

      expect(broken.months, isNull);
      expect(broken.monthlyPriceFils, isNull);
      expect(broken.isMultiMonth, isFalse);
    });
  });

  group('ProProgram plan rules', () {
    test('bestValuePlan: the live plans → annual', () {
      expect(_liveProgram.bestValuePlan, _annualPlan);
    });

    test('bestValuePlan: a single plan has nothing to beat → null', () {
      const program = ProProgram(enabled: true, plans: [_monthlyPlan]);

      expect(program.bestValuePlan, isNull);
    });

    test('bestValuePlan: equal per-month prices → null', () {
      const program = ProProgram(
        enabled: true,
        plans: [
          ProPlan(id: 'm', name: 'M', priceFils: 1000),
          ProPlan(
            id: 'y',
            name: 'Y',
            interval: ProBillingInterval.year,
            priceFils: 12000,
          ),
        ],
      );

      expect(program.bestValuePlan, isNull);
    });

    test('bestValuePlan: an unknown-interval plan is ignored', () {
      const withOdd = ProProgram(
        enabled: true,
        plans: [_oddPlan, _monthlyPlan, _annualPlan],
      );
      const onlyOneComparable = ProProgram(
        enabled: true,
        plans: [_monthlyPlan, _oddPlan],
      );

      expect(withOdd.bestValuePlan, _annualPlan);
      expect(onlyOneComparable.bestValuePlan, isNull);
    });

    test('savingPercentOf: annual saves 31% (website rounding)', () {
      expect(_liveProgram.savingPercentOf(_annualPlan), 31);
      expect(_liveProgram.savingPercentOf(_monthlyPlan), 0);
      expect(_liveProgram.savingPercentOf(_oddPlan), 0);
    });

    test('badgeSavings: only the best-value plan wears a chip, in plan '
        'order', () {
      // Quarterly saves too (2.500 vs 2.999 a month), but only the annual
      // plan is the best value.
      const program = ProProgram(
        enabled: true,
        plans: [_monthlyPlan, _quarterlyPlan, _annualPlan],
      );

      expect(program.savingPercentOf(_quarterlyPlan), greaterThan(0));
      expect(program.badgeSavings, [0, 0, 31]);
      expect(_liveProgram.badgeSavings, [0, 31]);
    });

    test('badgeSavings: all zeros when no plan can be compared', () {
      const program = ProProgram(
        enabled: true,
        plans: [_oddPlan, _monthlyPlan],
      );

      expect(program.badgeSavings, [0, 0]);
      expect(ProProgram.empty.badgeSavings, isEmpty);
    });

    test('badgeSavings: all zeros when every plan costs the same a month', () {
      const program = ProProgram(
        enabled: true,
        plans: [
          ProPlan(id: 'm', name: 'M', priceFils: 1000),
          ProPlan(
            id: 'y',
            name: 'Y',
            interval: ProBillingInterval.year,
            priceFils: 12000,
          ),
        ],
      );

      expect(program.badgeSavings, [0, 0]);
    });

    test('initialPlan: the current plan wins over the best value', () {
      expect(_liveProgram.initialPlan(currentPlanId: 'monthly'), _monthlyPlan);
    });

    test('initialPlan: no (or an unknown) current plan → best value', () {
      expect(_liveProgram.initialPlan(), _annualPlan);
      expect(_liveProgram.initialPlan(currentPlanId: 'gone'), _annualPlan);
    });

    test('initialPlan: no best value → the first plan; no plan → null', () {
      const single = ProProgram(enabled: true, plans: [_monthlyPlan]);
      const noComparison = ProProgram(
        enabled: true,
        plans: [_oddPlan, _monthlyPlan],
      );

      expect(single.initialPlan(), _monthlyPlan);
      expect(noComparison.initialPlan(), _oddPlan);
      expect(ProProgram.empty.initialPlan(), isNull);
      expect(ProProgram.empty.initialPlan(currentPlanId: 'monthly'), isNull);
    });

    test('planById: unknown or null → null', () {
      expect(_liveProgram.planById('annual'), _annualPlan);
      expect(_liveProgram.planById('nope'), isNull);
      expect(_liveProgram.planById(null), isNull);
    });
  });

  group('DTOs + mappers (live payload)', () {
    test('plans come out in backend order with their perks', () {
      final program = ProProgramModel.fromJson(_livePlans).toEntity();

      expect(program.enabled, isTrue);
      expect(program.isUnavailable, isFalse);
      expect(
        [for (final plan in program.plans) plan.slug],
        ['monthly', 'annual'],
      );
      expect(program.plans.first.interval, ProBillingInterval.month);
      expect(program.plans.first.priceKd, 2.999);
      expect(program.plans.last.interval, ProBillingInterval.year);
      expect(program.perks.freeDelivery, isTrue);
      expect(program.perks.pointsMultiplier, 2);
      expect(program.perks.discountPercent, 5);
    });

    test('a disabled programme / a plan without an id', () {
      final program = ProProgramModel.fromJson({
        'enabled': false,
        'data': [
          {'name': 'no id'},
        ],
      }).toEntity();

      expect(program.plans, isEmpty);
      expect(program.isUnavailable, isTrue);
    });

    test('subscription status, period end and cancel rule', () {
      final active = ProSubscriptionModel.fromJson(_subscriptionJson)
          .toEntity();
      final ending = ProSubscriptionModel.fromJson({
        ..._subscriptionJson,
        'cancelAtPeriodEnd': true,
      }).toEntity();
      final unknown = ProSubscriptionModel.fromJson({
        ..._subscriptionJson,
        'status': 'paused',
      }).toEntity();

      expect(active.isActive, isTrue);
      expect(active.canCancel, isTrue);
      expect(active.currentPeriodEnd, DateTime.utc(2026, 10, 17));
      expect(ending.canCancel, isFalse);
      expect(unknown.status, ProSubscriptionStatus.other);
      expect(unknown.isActive, isFalse);
    });

    test('hasBenefits: active, or cancelled while the period runs; never '
        'expired', () {
      ProSubscription of(String status, {bool atPeriodEnd = false}) =>
          ProSubscriptionModel.fromJson({
            ..._subscriptionJson,
            'status': status,
            'cancelAtPeriodEnd': atPeriodEnd,
          }).toEntity();

      expect(of('active').hasBenefits, isTrue);
      expect(of('active', atPeriodEnd: true).hasBenefits, isTrue);
      // The docs' shape of a cancelled subscription whose period still runs.
      final cancelledRunning = of('cancelled', atPeriodEnd: true);
      expect(cancelledRunning.hasBenefits, isTrue);
      expect(cancelledRunning.canCancel, isFalse);
      expect(of('cancelled').hasBenefits, isFalse);
      expect(of('expired', atPeriodEnd: true).hasBenefits, isFalse);
      expect(of('paused').hasBenefits, isFalse);
    });
  });

  group('ProMembershipRemoteDataSourceImpl', () {
    late FakeHttpClientAdapter adapter;

    ProMembershipRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return ProMembershipRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );
    }

    test('getProgram GETs /v1/subscription-plans', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(_livePlans)),
      );

      final program = await dataSource.getProgram();

      expect(adapter.requests.single.path, EndPoints.subscriptionPlans);
      expect(program.plans, hasLength(2));
    });

    test('getSubscription: results null = no subscription', () async {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));

      expect(await dataSource.getSubscription(), isNull);
      expect(adapter.requests.single.path, EndPoints.accountSubscription);
    });

    test('subscribe POSTs { planId }; cancel POSTs the cancel route', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(_subscriptionJson)),
      );

      final subscription = await dataSource.subscribe('plan-1');
      await dataSource.cancel();

      expect(adapter.requests.first.method, 'POST');
      expect(adapter.requests.first.path, EndPoints.accountSubscription);
      expect(adapter.requests.first.data, {'planId': 'plan-1'});
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.path, EndPoints.accountSubscriptionCancel);
      expect(subscription.status, 'active');
    });
  });

  group('ProMembershipRepositoryImpl', () {
    test(
      'a guest gets UnauthorizedFailure from the subscription route',
      () async {
        final remote = _ScriptedRemote()
          ..error = const UnauthorizedException('Authentication required');
        final repository = ProMembershipRepositoryImpl(
          remote,
          _catalogOn(FakeHttpClientAdapter((_, _) => okBody(null))),
        );

        final subscription = await repository.getSubscription();
        final program = await repository.getProgram();

        expect(
          subscription.swap().getOrElse(() => throw StateError('right')),
          isA<UnauthorizedFailure>(),
        );
        expect(program.isRight(), isTrue);
      },
    );
  });

  group('ProMembershipCubit', () {
    test('a guest sees the plans; signed-out is not an error', () async {
      final repository = _FakeRepository()
        ..subscription = const Left(UnauthorizedFailure('sign in'));
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.status, ProMembershipStatus.loaded);
      expect(cubit.state.isSignedOut, isTrue);
      expect(cubit.state.subscription, isNull);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a failed programme is the error state; retry recovers', () async {
      final repository = _FakeRepository()
        ..program = const Left(NetworkFailure('offline'));
      final cubit = _cubit(repository);

      await cubit.load();
      expect(cubit.state.status, ProMembershipStatus.error);

      repository.program = const Right(ProProgram(enabled: true));
      await cubit.load();
      expect(cubit.state.status, ProMembershipStatus.loaded);
      await cubit.close();
    });

    test('subscribe waits for the server and cannot fire twice', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load();

      final first = cubit.subscribe('monthly');
      unawaited(cubit.subscribe('monthly')); // double tap
      unawaited(cubit.cancelSubscription()); // other action while busy
      expect(cubit.state.submittingPlanId, 'monthly');
      expect(cubit.state.isMember, isFalse); // nothing optimistic
      expect(repository.subscribeCalls, hasLength(1));
      expect(repository.cancelCalls, 0);

      repository.subscribeCalls.single.complete(const Right(_monthly));
      await first;

      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.isMember, isTrue);
      expect(cubit.state.outcome, ProMembershipOutcome.subscribed);
      await cubit.close();
    });

    test('a reload landing during a subscribe never overwrites it', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load();

      final subscribing = cubit.subscribe('monthly');
      await cubit.refresh(); // replies "no subscription" while we are busy
      expect(cubit.state.submittingPlanId, 'monthly');

      repository.subscribeCalls.single.complete(const Right(_monthly));
      await subscribing;

      expect(cubit.state.subscription, _monthly);
      await cubit.close();
    });

    test('a reload asked for before a subscribe, landing after it, is '
        'dropped', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load();

      final gate = repository.subscriptionGate = Completer<void>();
      final reload = cubit.refresh(); // its GET is held open
      final subscribing = cubit.subscribe('monthly');
      repository.subscribeCalls.single.complete(const Right(_monthly));
      await subscribing;
      expect(cubit.state.isMember, isTrue);

      gate.complete(); // the old reply: "no subscription"
      await reload;

      expect(cubit.state.subscription, _monthly);
      expect(cubit.state.isMember, isTrue);
      await cubit.close();
    });

    test('a reload asked for before a cancel, landing after it, is '
        'dropped', () async {
      final repository = _FakeRepository()
        ..subscription = const Right(_monthly);
      final cubit = _cubit(repository);
      await cubit.load();
      expect(cubit.state.subscription!.canCancel, isTrue);

      final gate = repository.subscriptionGate = Completer<void>();
      final reload = cubit.refresh(); // its GET is held open
      await cubit.cancelSubscription();
      expect(cubit.state.subscription!.cancelAtPeriodEnd, isTrue);

      gate.complete(); // the old reply: the renewing subscription
      await reload;

      expect(cubit.state.subscription!.cancelAtPeriodEnd, isTrue);
      expect(cubit.state.subscription!.canCancel, isFalse);
      await cubit.close();
    });

    test('a reload asked for after a subscribe still lands', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      await cubit.load();
      final subscribing = cubit.subscribe('monthly');
      repository.subscribeCalls.single.complete(const Right(_monthly));
      await subscribing;

      // The server's newer answer (e.g. cancelled from another device).
      const cancelledElsewhere = ProSubscription(
        id: 'sub1',
        planId: 'monthly',
        status: ProSubscriptionStatus.active,
        cancelAtPeriodEnd: true,
      );
      repository.subscription = const Right(cancelledElsewhere);
      await cubit.refresh();

      expect(cubit.state.subscription, cancelledElsewhere);
      await cubit.close();
    });

    test('a failed subscription read on the first load is the error view '
        '(membership unknown); retry recovers', () async {
      final repository = _FakeRepository()
        ..subscription = const Left(ServerFailure('x', statusCode: 500));
      final cubit = _cubit(repository);

      await cubit.load();
      expect(cubit.state.status, ProMembershipStatus.error);
      expect(cubit.state.failure, isA<ServerFailure>());
      expect(cubit.state.isSignedOut, isFalse);

      repository.subscription = const Right(_monthly);
      await cubit.load();
      expect(cubit.state.status, ProMembershipStatus.loaded);
      expect(cubit.state.isMember, isTrue);
      await cubit.close();
    });

    test('a failed subscription read on a loaded page keeps the membership '
        'and surfaces the failure', () async {
      final repository = _FakeRepository()
        ..subscription = const Right(_monthly);
      final cubit = _cubit(repository);
      await cubit.load();

      repository.subscription = const Left(NetworkFailure('offline'));
      await cubit.refresh();

      expect(cubit.state.status, ProMembershipStatus.loaded);
      expect(cubit.state.subscription, _monthly);
      expect(cubit.state.isMember, isTrue);
      expect(cubit.state.failure, isA<NetworkFailure>());
      await cubit.close();
    });

    test(
      'a guest whose reload fails on the network stays signed out',
      () async {
        final repository = _FakeRepository()
          ..subscription = const Left(UnauthorizedFailure('sign in'));
        final cubit = _cubit(repository);
        await cubit.load();
        expect(cubit.state.isSignedOut, isTrue);

        repository.subscription = const Left(NetworkFailure('offline'));
        await cubit.refresh();

        expect(cubit.state.status, ProMembershipStatus.loaded);
        expect(cubit.state.isSignedOut, isTrue);
        expect(cubit.state.subscription, isNull);
        await cubit.close();
      },
    );

    test(
      'a refused subscribe leaves the state untouched + surfaces it',
      () async {
        final repository = _FakeRepository();
        final cubit = _cubit(repository);
        await cubit.load();

        final subscribing = cubit.subscribe('monthly');
        repository.subscribeCalls.single.complete(
          const Left(ServerFailure('Payment failed', statusCode: 400)),
        );
        await subscribing;

        expect(cubit.state.isBusy, isFalse);
        expect(cubit.state.isMember, isFalse);
        expect(cubit.state.outcome, isNull);
        expect(cubit.state.failure, isA<ServerFailure>());
        await cubit.close();
      },
    );

    test(
      'cancel only applies to an active, not yet cancelled subscription',
      () async {
        final repository = _FakeRepository();
        final cubit = _cubit(repository);
        await cubit.load();
        await cubit.cancelSubscription(); // no subscription
        expect(repository.cancelCalls, 0);

        repository.subscription = const Right(_monthly);
        await cubit.refresh();
        await cubit.cancelSubscription();

        expect(repository.cancelCalls, 1);
        expect(cubit.state.subscription?.cancelAtPeriodEnd, isTrue);
        expect(cubit.state.outcome, ProMembershipOutcome.cancelled);

        await cubit.cancelSubscription(); // already cancelled
        expect(repository.cancelCalls, 1);
        await cubit.close();
      },
    );

    test('an empty plan id is refused before the network', () async {
      final repository = _FakeRepository();

      final result = await SubscribeToProUseCase(repository)(
        const SubscribeToProParams(''),
      );

      expect(result.isLeft(), isTrue);
      expect(repository.subscribeCalls, isEmpty);
    });
  });

  group('ProMembershipCubit plan selection', () {
    _FakeRepository live() =>
        _FakeRepository()..program = const Right(_liveProgram);

    test('a guest opens on the best-value plan (annual)', () async {
      final repository = live()
        ..subscription = const Left(UnauthorizedFailure('sign in'));
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.selectedPlanId, 'annual');
      expect(cubit.state.selectedPlan, _annualPlan);
      await cubit.close();
    });

    test('a non-member opens on the best-value plan (annual)', () async {
      final cubit = _cubit(live());

      await cubit.load();

      expect(cubit.state.isMember, isFalse);
      expect(cubit.state.selectedPlanId, 'annual');
      await cubit.close();
    });

    test('a member opens on their current plan', () async {
      final repository = live()..subscription = const Right(_monthly);
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.isMember, isTrue);
      expect(cubit.state.selectedPlanId, 'monthly');
      await cubit.close();
    });

    test('an expired subscription does not pin its plan', () async {
      final repository = live()
        ..subscription = const Right(
          ProSubscription(
            id: 'sub0',
            planId: 'monthly',
            status: ProSubscriptionStatus.expired,
          ),
        );
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.selectedPlanId, 'annual');
      await cubit.close();
    });

    test('selectPlan switches; an unknown id is ignored', () async {
      final cubit = _cubit(live());
      await cubit.load();

      cubit.selectPlan('monthly');
      expect(cubit.state.selectedPlanId, 'monthly');

      final before = cubit.state;
      cubit.selectPlan('nope');
      expect(cubit.state, same(before));
      await cubit.close();
    });

    test('a member cannot switch plans: the tabs stay on theirs', () async {
      final repository = live()..subscription = const Right(_monthly);
      final cubit = _cubit(repository);
      await cubit.load();

      final before = cubit.state;
      cubit.selectPlan('annual');

      expect(cubit.state, same(before));
      expect(cubit.state.selectedPlanId, 'monthly');
      await cubit.close();
    });

    test(
      'a refresh that finds a membership re-centres on the owned plan',
      () async {
        final repository = live();
        final cubit = _cubit(repository);
        await cubit.load();
        expect(
          cubit.state.selectedPlanId,
          'annual',
        ); // best value, not a member

        // Subscribed to the monthly plan elsewhere (another device, the web).
        repository.subscription = const Right(_monthly);
        await cubit.refresh();

        expect(cubit.state.isMember, isTrue);
        expect(cubit.state.selectedPlanId, 'monthly');
        await cubit.close();
      },
    );

    test('planSavings: the best-value chip for a non-member, none for a '
        'member', () async {
      final repository = live();
      final cubit = _cubit(repository);
      await cubit.load();
      expect(cubit.state.planSavings, [0, 31]);

      repository.subscription = const Right(_monthly);
      await cubit.refresh();
      expect(cubit.state.planSavings, [0, 0]);
      await cubit.close();
    });

    test('selectPlan is ignored while a subscribe is in flight', () async {
      final repository = live();
      final cubit = _cubit(repository);
      await cubit.load();

      final subscribing = cubit.subscribe('annual');
      cubit.selectPlan('monthly');
      expect(cubit.state.selectedPlanId, 'annual');

      repository.subscribeCalls.single.complete(
        const Left(ServerFailure('Payment failed', statusCode: 400)),
      );
      await subscribing;
      expect(cubit.state.selectedPlanId, 'annual');
      await cubit.close();
    });

    test('a refresh keeps the customer pick', () async {
      final cubit = _cubit(live());
      await cubit.load();
      cubit.selectPlan('monthly');

      await cubit.refresh();

      expect(cubit.state.selectedPlanId, 'monthly');
      await cubit.close();
    });

    test('a pick the reloaded programme no longer sells falls back to '
        'initialPlan', () async {
      final repository = live();
      final cubit = _cubit(repository);
      await cubit.load();
      cubit.selectPlan('monthly');

      repository.program = const Right(
        ProProgram(enabled: true, plans: [_quarterlyPlan, _annualPlan]),
      );
      await cubit.refresh();

      expect(cubit.state.selectedPlanId, 'annual');
      await cubit.close();
    });

    test('a cancelled subscription whose period still runs is a member on '
        'its plan: no join button', () async {
      final repository = live()
        ..subscription = const Right(
          ProSubscription(
            id: 'sub1',
            planId: 'monthly',
            status: ProSubscriptionStatus.cancelled,
            cancelAtPeriodEnd: true,
          ),
        );
      final cubit = _cubit(repository);

      await cubit.load();

      expect(cubit.state.isMember, isTrue);
      expect(cubit.state.selectedPlanId, 'monthly');
      expect(cubit.state.subscription!.canCancel, isFalse);
      await cubit.close();
    });

    test('a reloaded programme without plans clears the pick', () async {
      final repository = live();
      final cubit = _cubit(repository);
      await cubit.load();
      cubit.selectPlan('monthly');

      repository.program = const Right(ProProgram(enabled: true));
      await cubit.refresh();
      expect(cubit.state.selectedPlanId, isNull);
      expect(cubit.state.selectedPlan, isNull);

      // The plan coming back later opens on the default, not the stale pick.
      repository.program = const Right(_liveProgram);
      await cubit.refresh();
      expect(cubit.state.selectedPlanId, 'annual');
      await cubit.close();
    });

    test('after a subscribe the selection is the subscribed plan', () async {
      final repository = live();
      final cubit = _cubit(repository);
      await cubit.load();
      expect(cubit.state.selectedPlanId, 'annual');

      final subscribing = cubit.subscribe('monthly');
      repository.subscribeCalls.single.complete(const Right(_monthly));
      await subscribing;

      expect(cubit.state.selectedPlanId, 'monthly');
      expect(cubit.state.outcome, ProMembershipOutcome.subscribed);
      await cubit.close();
    });
  });

  group('ProMembershipRepositoryImpl.getBrands', () {
    test('GETs the first page of /v1/brands and maps the rows', () async {
      final adapter = FakeHttpClientAdapter(
        (_, _) => okBody({
          'data': [
            {
              '_id': 'b1',
              'slug': 'almarai',
              'name': 'Almarai',
              'image': 'https://cdn.example/almarai.jpg',
            },
            {'_id': 'b2', 'slug': 'kdd', 'name': 'KDD'},
            {'_id': 'b3', 'name': 'no slug'}, // dropped, not fatal
          ],
          'pagination': {'total': 3, 'page': 1, 'limit': 20, 'hasMore': false},
        }),
      );
      final repository = ProMembershipRepositoryImpl(
        _ScriptedRemote(),
        _catalogOn(adapter),
      );

      final result = await repository.getBrands();

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, EndPoints.brands);
      expect(request.queryParameters, {
        'page': 1,
        'limit': ProMembershipRepositoryImpl.brandsLimit,
      });
      final brands = result.getOrElse(() => throw StateError('left'));
      expect(brands, [
        const BrandEntity(
          id: 'b1',
          slug: 'almarai',
          name: 'Almarai',
          image: 'https://cdn.example/almarai.jpg',
        ),
        _kdd,
      ]);
      expect(brands.last.image, '');
      expect(brands.last.hasImage, isFalse);
      expect(brands.last.initial, 'K');
    });

    test('a transport failure is a Left(NetworkFailure)', () async {
      final repository = ProMembershipRepositoryImpl(
        _ScriptedRemote(),
        _catalogOn(
          FakeHttpClientAdapter(
            (options, _) => throw DioException.connectionError(
              requestOptions: options,
              reason: 'refused',
            ),
          ),
        ),
      );

      final result = await repository.getBrands();

      expect(
        result.swap().getOrElse(() => throw StateError('right')),
        isA<NetworkFailure>(),
      );
    });

    test('GetProBrandsUseCase passes the repository reply through', () async {
      final result = await GetProBrandsUseCase(_FakeRepository())(
        const NoParams(),
      );

      expect(result.getOrElse(() => throw StateError('left')), isEmpty);
    });
  });

  group('ProBrandsCubit', () {
    test('emits the loaded brands as an unmodifiable list', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);
      expect(cubit.state.brands, isEmpty);

      final loading = cubit.load();
      useCase.calls.single.complete(const Right([_almarai, _kdd]));
      await loading;

      expect(cubit.state.brands, [_almarai, _kdd]);
      expect(() => cubit.state.brands.add(_almarai), throwsUnsupportedError);
      await cubit.close();
    });

    test('an empty reply emits nothing (the state is unchanged)', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);
      final emitted = <ProBrandsState>[];
      final subscription = cubit.stream.listen(emitted.add);

      final loading = cubit.load();
      useCase.calls.single.complete(const Right(<BrandEntity>[]));
      await loading;
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      expect(cubit.state.brands, isEmpty);
      await subscription.cancel();
      await cubit.close();
    });

    test('a reload with the same brands emits nothing', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);
      final first = cubit.load();
      useCase.calls.single.complete(const Right([_almarai, _kdd]));
      await first;
      final emitted = <ProBrandsState>[];
      final subscription = cubit.stream.listen(emitted.add);

      final second = cubit.load();
      // Another list instance with the same brands.
      useCase.calls.last.complete(Right(List.of(const [_almarai, _kdd])));
      await second;
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      expect(cubit.state.brands, [_almarai, _kdd]);
      await subscription.cancel();
      await cubit.close();
    });

    test('an empty reply after brands were shown clears them', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);
      final first = cubit.load();
      useCase.calls.single.complete(const Right([_almarai]));
      await first;

      final second = cubit.load();
      useCase.calls.last.complete(const Right(<BrandEntity>[]));
      await second;

      expect(cubit.state.brands, isEmpty);
      await cubit.close();
    });

    test('a failure keeps the brands it already had', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);
      final first = cubit.load();
      useCase.calls.single.complete(const Right([_almarai, _kdd]));
      await first;

      final second = cubit.load();
      useCase.calls.last.complete(const Left(NetworkFailure('offline')));
      await second;

      expect(cubit.state.brands, [_almarai, _kdd]);
      await cubit.close();
    });

    test('an older reply landing after a newer one is dropped', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);

      final older = cubit.load();
      final newer = cubit.load();
      useCase.calls.last.complete(const Right([_kdd]));
      await newer;
      useCase.calls.first.complete(const Right([_almarai, _kdd]));
      await older;

      expect(cubit.state.brands, [_kdd]);
      await cubit.close();
    });

    test('a reply after close is ignored', () async {
      final useCase = _GatedBrandsUseCase();
      final cubit = ProBrandsCubit(useCase);

      final loading = cubit.load();
      await cubit.close();
      useCase.calls.single.complete(const Right([_almarai]));
      await loading;

      expect(cubit.isClosed, isTrue);
      expect(cubit.state.brands, isEmpty);
    });
  });
}
