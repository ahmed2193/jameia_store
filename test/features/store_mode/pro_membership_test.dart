// Pro membership (what replaced the offline VIP ⇄ Mart store mode): DTOs fed
// with the live plans payload, the remote datasource, the repository's failure
// mapping and the cubit's money-action rules (guest, double submit, a reload
// landing during a subscribe).
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_program_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_subscription_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/subscribe_to_pro_usecase.dart';
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

  @override
  Future<Either<Failure, ProProgram>> getProgram() async => program;

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() async =>
      subscription;

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
}

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
        final repository = ProMembershipRepositoryImpl(remote);

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
        expect(const NoParams(), const NoParams());
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
}
