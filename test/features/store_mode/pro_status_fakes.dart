import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/brand_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:jameia_mart/src/features/store_mode/domain/repositories/pro_membership_repository.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_membership_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/domain/usecases/get_pro_program_usecase.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';

import '../../core/data/snapshot_test_fakes.dart';

/// The live programme (2026-09): free delivery, ×2 points, 5% off; Monthly
/// 2.999 KD.
const ProProgram kProProgram = ProProgram(
  enabled: true,
  perks: ProPerks(freeDelivery: true, pointsMultiplier: 2, discountPercent: 5),
  plans: [ProPlan(id: 'monthly', name: 'Monthly', priceFils: 2999)],
);

/// A Pro repository that answers from its fields, for the app-global Pro
/// status in widget tests of other features.
class FakeProStatusRepository implements ProMembershipRepository {
  FakeProStatusRepository({
    this.program = const Right(kProProgram),
    this.subscription = const Right(null),
  });

  Either<Failure, ProProgram> program;
  Either<Failure, ProSubscription?> subscription;

  @override
  Future<Either<Failure, ProProgram>> getProgram() async => program;

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() async =>
      subscription;

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

/// An app-global Pro status over [repository] (the live programme, no
/// subscription by default). Idle — the standing unknown, nothing offered —
/// until the test calls `stop()` (a guest) or `start(customer)`, or uses
/// [settledProStatus].
ProStatusCubit buildProStatus([FakeProStatusRepository? repository]) {
  final source = repository ?? FakeProStatusRepository();
  return ProStatusCubit(
    GetProMembershipUseCase(source),
    GetProProgramUseCase(source),
  );
}

/// A Pro status already settled: a guest when [customer] is `null`, else
/// that customer with [subscription] (none = a prospect). Microtasks only —
/// safe inside `testWidgets`; the programme lands with the next pump (or
/// `pumpEventQueue` in a plain test). Close it before a widget test ends: a
/// member's status watches the end of the paid period with a timer.
Future<ProStatusCubit> settledProStatus({
  AuthCustomerEntity? customer,
  ProSubscription? subscription,
  ProProgram program = kProProgram,
}) async {
  final cubit = buildProStatus(
    FakeProStatusRepository(
      program: Right(program),
      subscription: Right(subscription),
    ),
  );
  if (customer == null) {
    cubit.stop();
  } else {
    await cubit.start(customer);
  }
  return cubit;
}
