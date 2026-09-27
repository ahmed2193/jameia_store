// The app-global Pro status: where a customer stands with Pro (guest,
// prospect, renewing, ending, lapsed) from their record and their
// subscription, the use case that reads it, and the cubit's rules — the
// record at once, the subscription after; a stale reply after sign-out or
// after the Pro page's fresher answer is dropped; the programme read once.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/brand_entity.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/pro_membership_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:hero_mart/src/features/store_mode/domain/repositories/pro_membership_repository.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/get_pro_membership_usecase.dart';
import 'package:hero_mart/src/features/store_mode/domain/usecases/get_pro_program_usecase.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';

import '../../core/data/snapshot_test_fakes.dart';

final DateTime _periodEnd = DateTime.utc(2026, 10, 17);

const AuthCustomerEntity _customer = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
);

final AuthCustomerEntity _member = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
  isPro: true,
  proExpiresAt: _periodEnd,
);

ProSubscription _subscription({
  ProSubscriptionStatus status = ProSubscriptionStatus.active,
  bool cancelAtPeriodEnd = false,
}) => ProSubscription(
  id: 'sub1',
  planId: 'monthly',
  planName: 'Monthly',
  status: status,
  currentPeriodEnd: _periodEnd,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
);

const ProProgram _program = ProProgram(
  enabled: true,
  perks: ProPerks(freeDelivery: true, pointsMultiplier: 2, discountPercent: 5),
  plans: [ProPlan(id: 'monthly', name: 'Monthly', priceFils: 2999)],
);

class _FakeRepository implements ProMembershipRepository {
  Either<Failure, ProProgram> program = const Right(_program);
  Either<Failure, ProSubscription?> subscription = const Right(null);
  int programCalls = 0;
  int subscriptionCalls = 0;

  /// While set, the subscription read waits for it (a read still in flight).
  Completer<void>? subscriptionGate;

  @override
  Future<Either<Failure, ProProgram>> getProgram() async {
    programCalls++;
    return program;
  }

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() async {
    subscriptionCalls++;
    final reply = subscription;
    await subscriptionGate?.future;
    return reply;
  }

  @override
  Stream<DataSnapshot<ProProgram>> watchProgram({bool forceRefresh = false}) =>
      networkRead(getProgram());

  @override
  Stream<DataSnapshot<ProSubscription?>> watchSubscription({
    bool forceRefresh = false,
  }) => networkRead(getSubscription());

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) async =>
      const Left(NetworkFailure());

  @override
  Future<Either<Failure, ProSubscription>> cancel() async =>
      const Left(NetworkFailure());

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async =>
      const Right(<BrandEntity>[]);
}

ProStatusCubit _cubit(_FakeRepository repository) => ProStatusCubit(
  GetProMembershipUseCase(repository),
  GetProProgramUseCase(repository),
);

void main() {
  group('onReconnected', () {
    test('an unconfirmed standing and a missing programme are asked '
        'again', () async {
      final repository = _FakeRepository()
        ..program = const Left(NetworkFailure())
        ..subscription = const Left(NetworkFailure());
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.start(_customer);
      await pumpEventQueue();
      expect(cubit.state.isConfirmed, isFalse);
      expect(cubit.state.isProgramLoaded, isFalse);

      repository
        ..program = const Right(_program)
        ..subscription = const Right(null);
      await cubit.onReconnected();
      await pumpEventQueue();

      expect(cubit.state.isConfirmed, isTrue);
      expect(cubit.state.isProgramLoaded, isTrue);
      expect(repository.subscriptionCalls, 2);
      expect(repository.programCalls, 2);
    });

    test('a confirmed standing, or a guest, asks nothing more', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.start(_customer);
      await pumpEventQueue();

      await cubit.onReconnected();
      cubit.stop();
      await cubit.onReconnected();
      await pumpEventQueue();

      expect(repository.subscriptionCalls, 1);
      expect(repository.programCalls, 1);
    });
  });

  group('ProMembershipEntity', () {
    test('a customer record: a member renews until pro.expiresAt', () {
      final membership = ProMembershipEntity.ofCustomer(_member);

      expect(membership.standing, ProStanding.active);
      expect(membership.periodEnd, _periodEnd);
      expect(membership.hasBenefits, isTrue);
      expect(membership.canJoin, isFalse);
    });

    test('a customer record without Pro is a prospect', () {
      final membership = ProMembershipEntity.ofCustomer(_customer);

      expect(membership, ProMembershipEntity.prospect);
      expect(membership.hasBenefits, isFalse);
      expect(membership.canJoin, isTrue);
    });

    test('a guest has no perks and may join', () {
      expect(ProMembershipEntity.guest.isGuest, isTrue);
      expect(ProMembershipEntity.guest.hasBenefits, isFalse);
      expect(ProMembershipEntity.guest.canJoin, isTrue);
    });
  });

  group('ProSubscription.membership', () {
    test('active and renewing → active, with the renewal date and plan', () {
      final membership = _subscription().membership;

      expect(membership.standing, ProStanding.active);
      expect(membership.periodEnd, _periodEnd);
      expect(membership.planName, 'Monthly');
    });

    test('cancelled while the period runs → ending (perks still on)', () {
      for (final status in [
        ProSubscriptionStatus.cancelled,
        ProSubscriptionStatus.active,
      ]) {
        final membership = _subscription(
          status: status,
          cancelAtPeriodEnd: true,
        ).membership;

        expect(membership.standing, ProStanding.ending, reason: '$status');
        expect(membership.hasBenefits, isTrue);
      }
    });

    test('expired, or cancelled with nothing left → lapsed', () {
      expect(
        _subscription(status: ProSubscriptionStatus.expired)
            .membership
            .standing,
        ProStanding.lapsed,
      );
      expect(
        _subscription(
          status: ProSubscriptionStatus.expired,
          cancelAtPeriodEnd: true,
        ).membership.standing,
        ProStanding.lapsed,
      );
      expect(
        _subscription(status: ProSubscriptionStatus.cancelled)
            .membership
            .standing,
        ProStanding.lapsed,
      );
    });

    test('an unknown status is no membership', () {
      expect(
        _subscription(status: ProSubscriptionStatus.other).membership.standing,
        ProStanding.prospect,
      );
    });
  });

  group('GetProMembershipUseCase', () {
    test('no subscription → a prospect', () async {
      final repository = _FakeRepository();

      final result = await GetProMembershipUseCase(repository)(
        const NoParams(),
      );

      expect(
        result,
        const Right<Failure, ProMembershipEntity>(ProMembershipEntity.prospect),
      );
    });

    test('a subscription → its standing; a failure passes through', () async {
      final repository = _FakeRepository()
        ..subscription = Right(_subscription(cancelAtPeriodEnd: true));
      final useCase = GetProMembershipUseCase(repository);

      final ending = await useCase(const NoParams());
      expect(
        ending.getOrElse(() => ProMembershipEntity.guest).standing,
        ProStanding.ending,
      );

      repository.subscription = const Left(UnauthorizedFailure());
      final guest = await useCase(const NoParams());
      expect(guest.isLeft(), isTrue);
    });
  });

  group('ProStatusCubit', () {
    test('starts unsettled: a guest, nothing offered', () async {
      final cubit = _cubit(_FakeRepository());

      expect(cubit.state.isSettled, isFalse);
      expect(cubit.state.membership, ProMembershipEntity.guest);
      expect(cubit.state.canOffer, isFalse);
      await cubit.close();
    });

    test('stop: a settled guest; the programme is read once', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);

      cubit.stop();
      await pumpEventQueue();
      cubit.stop();
      await pumpEventQueue();

      expect(cubit.state.isSettled, isTrue);
      expect(cubit.state.membership.isGuest, isTrue);
      expect(cubit.state.canOffer, isTrue);
      expect(cubit.state.offersFreeDelivery, isTrue);
      expect(repository.programCalls, 1);
      await cubit.close();
    });

    test(
      'start: the record at once, then the subscription refines it',
      () async {
        final gate = Completer<void>();
        final repository = _FakeRepository()
          ..subscription = Right(_subscription(cancelAtPeriodEnd: true))
          ..subscriptionGate = gate;
        final cubit = _cubit(repository);

        final started = cubit.start(_member);
        await pumpEventQueue();
        expect(cubit.state.membership.standing, ProStanding.active);
        expect(cubit.state.isSettled, isTrue);
        expect(cubit.state.isConfirmed, isFalse);

        gate.complete();
        await started;
        expect(cubit.state.membership.standing, ProStanding.ending);
        expect(cubit.state.isConfirmed, isTrue);
        expect(cubit.state.canOffer, isFalse);
        await cubit.close();
      },
    );

    test('a lapsed member may be offered Pro again', () async {
      final repository = _FakeRepository()
        ..subscription = Right(
          _subscription(status: ProSubscriptionStatus.expired),
        );
      final cubit = _cubit(repository);

      await cubit.start(_customer);
      await pumpEventQueue();

      expect(cubit.state.membership.standing, ProStanding.lapsed);
      expect(cubit.state.canOffer, isTrue);
      await cubit.close();
    });

    test('a failed read keeps what the record said', () async {
      final repository = _FakeRepository()
        ..subscription = const Left(NetworkFailure());
      final cubit = _cubit(repository);

      await cubit.start(_member);

      expect(cubit.state.membership.standing, ProStanding.active);
      expect(cubit.state.isSettled, isTrue);
      expect(cubit.state.isConfirmed, isFalse);
      await cubit.close();
    });

    test(
      'signed in with no record: unsettled until the route answers',
      () async {
        final gate = Completer<void>();
        final repository = _FakeRepository()
          ..subscription = Right(_subscription())
          ..subscriptionGate = gate;
        final cubit = _cubit(repository)..stop();

        final started = cubit.start(null);
        await pumpEventQueue();
        expect(cubit.state.membership.isGuest, isFalse);
        expect(cubit.state.isSettled, isFalse);
        expect(cubit.state.canOffer, isFalse);

        gate.complete();
        await started;
        expect(cubit.state.membership.standing, ProStanding.active);
        expect(cubit.state.isSettled, isTrue);
        await cubit.close();
      },
    );

    test('a confirmed answer that agrees survives a record change', () async {
      final repository = _FakeRepository()
        ..subscription = Right(_subscription(cancelAtPeriodEnd: true));
      final cubit = _cubit(repository);
      await cubit.start(_member);
      expect(cubit.state.membership.standing, ProStanding.ending);

      final gate = Completer<void>();
      repository.subscriptionGate = gate;
      final restarted = cubit.start(_member);
      await pumpEventQueue();
      // Still "ending" while the second read is in flight — no flicker back
      // to "renewing".
      expect(cubit.state.membership.standing, ProStanding.ending);

      gate.complete();
      await restarted;
      await cubit.close();
    });

    test('a read still in flight at sign-out is dropped', () async {
      final gate = Completer<void>();
      final repository = _FakeRepository()
        ..subscription = Right(_subscription())
        ..subscriptionGate = gate;
      final cubit = _cubit(repository);

      final started = cubit.start(_member);
      await pumpEventQueue();
      cubit.stop();
      gate.complete();
      await started;

      expect(cubit.state.membership.isGuest, isTrue);
      await cubit.close();
    });

    test("the Pro page's answer wins over an older read", () async {
      final gate = Completer<void>();
      final repository = _FakeRepository()
        ..subscription = Right(_subscription())
        ..subscriptionGate = gate;
      final cubit = _cubit(repository);

      final started = cubit.start(_member);
      await pumpEventQueue();
      // The customer cancelled on the Pro page meanwhile.
      cubit.apply(_subscription(cancelAtPeriodEnd: true).membership);
      gate.complete();
      await started;

      expect(cubit.state.membership.standing, ProStanding.ending);
      expect(cubit.state.isConfirmed, isTrue);
      await cubit.close();
    });

    test('apply is ignored for a guest', () async {
      final cubit = _cubit(_FakeRepository())..stop();

      cubit.apply(_subscription().membership);

      expect(cubit.state.membership.isGuest, isTrue);
      await cubit.close();
    });

    test('a failed programme read is retried with the next session', () async {
      final repository = _FakeRepository()
        ..program = const Left(NetworkFailure());
      final cubit = _cubit(repository)..stop();
      await pumpEventQueue();
      expect(cubit.state.isProgramLoaded, isFalse);
      expect(cubit.state.canOffer, isFalse);

      repository.program = const Right(_program);
      await cubit.start(_customer);
      await pumpEventQueue();

      expect(cubit.state.isProgramLoaded, isTrue);
      expect(repository.programCalls, 2);
      expect(cubit.state.canOffer, isTrue);
      await cubit.close();
    });

    test('a member is asked again once the paid period is over', () async {
      final now = DateTime.utc(2026, 9, 27, 12);
      final end = now.add(const Duration(milliseconds: 30));
      final repository = _FakeRepository()
        ..subscription = Right(
          ProSubscription(
            id: 'sub1',
            planId: 'monthly',
            status: ProSubscriptionStatus.active,
            currentPeriodEnd: end,
          ),
        );
      final cubit = ProStatusCubit(
        GetProMembershipUseCase(repository),
        GetProProgramUseCase(repository),
        now: () => now,
        expiryGrace: Duration.zero,
      );

      await cubit.start(_member);
      expect(cubit.state.membership.standing, ProStanding.active);
      expect(repository.subscriptionCalls, 1);

      // The backend ended the membership with the period.
      repository.subscription = Right(
        ProSubscription(
          id: 'sub1',
          planId: 'monthly',
          status: ProSubscriptionStatus.expired,
          currentPeriodEnd: end,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(repository.subscriptionCalls, 2);
      expect(cubit.state.membership.standing, ProStanding.lapsed);
      await cubit.close();
    });

    test('no second read for a period already over, a non-member, or after '
        'sign-out', () async {
      final now = DateTime.utc(2026, 9, 27, 12);
      final repository = _FakeRepository()
        ..subscription = Right(
          ProSubscription(
            id: 'sub1',
            planId: 'monthly',
            status: ProSubscriptionStatus.active,
            currentPeriodEnd: now.subtract(const Duration(days: 1)),
          ),
        );
      final cubit = ProStatusCubit(
        GetProMembershipUseCase(repository),
        GetProProgramUseCase(repository),
        now: () => now,
        expiryGrace: Duration.zero,
      );

      await cubit.start(_member);
      repository.subscription = Right(
        ProSubscription(
          id: 'sub1',
          planId: 'monthly',
          status: ProSubscriptionStatus.active,
          currentPeriodEnd: now.add(const Duration(milliseconds: 30)),
        ),
      );
      await cubit.refresh();
      expect(repository.subscriptionCalls, 2);
      cubit.stop();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(repository.subscriptionCalls, 2);
      expect(cubit.state.membership.isGuest, isTrue);
      await cubit.close();
    });

    test('refresh asks nothing for a guest', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository)..stop();

      await cubit.refresh();

      expect(repository.subscriptionCalls, 0);
      await cubit.close();
    });

    test('a store that stopped selling Pro offers nothing', () async {
      final repository = _FakeRepository()..program = const Right(ProProgram());
      final cubit = _cubit(repository)..stop();
      await pumpEventQueue();

      expect(cubit.state.isProgramLoaded, isTrue);
      expect(cubit.state.canOffer, isFalse);
      expect(cubit.state.offersFreeDelivery, isFalse);
      await cubit.close();
    });
  });
}
