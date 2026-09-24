import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/pro_membership.dart';

/// Pro membership boundary (jm3eia backend).
abstract class ProMembershipRepository {
  /// `GET /v1/subscription-plans` — public.
  Future<Either<Failure, ProProgram>> getProgram();

  /// `GET /v1/account/subscription` — signed-in only; `Right(null)` when the
  /// customer has none, `Left(UnauthorizedFailure)` for a guest.
  Future<Either<Failure, ProSubscription?>> getSubscription();

  /// `POST /v1/account/subscription { planId }` — signed-in only.
  Future<Either<Failure, ProSubscription>> subscribe(String planId);

  /// `POST /v1/account/subscription/cancel` — stops the renewal; the paid
  /// period keeps running.
  Future<Either<Failure, ProSubscription>> cancel();
}
