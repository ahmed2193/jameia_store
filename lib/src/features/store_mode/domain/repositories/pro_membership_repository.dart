import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../entities/pro_membership.dart';

/// Pro membership boundary (jm3eia backend).
abstract class ProMembershipRepository {
  /// `GET /v1/subscription-plans` — public; the server's answer.
  Future<Either<Failure, ProProgram>> getProgram();

  /// The programme as the Pro page reads it: the copy saved on the device
  /// first, then the server's (only the server's with [forceRefresh]);
  /// failures on the error channel.
  Stream<DataSnapshot<ProProgram>> watchProgram({bool forceRefresh = false});

  /// `GET /v1/account/subscription` — signed-in only; `Right(null)` when the
  /// customer has none, `Left(UnauthorizedFailure)` for a guest.
  Future<Either<Failure, ProSubscription?>> getSubscription();

  /// The subscription as the Pro page reads it: the signed-in customer's
  /// saved copy first (nothing is kept for a guest), then the server's;
  /// `null` = none, and a guest's read fails with `UnauthorizedFailure`.
  Stream<DataSnapshot<ProSubscription?>> watchSubscription({
    bool forceRefresh = false,
  });

  /// `POST /v1/account/subscription { planId }` — signed-in only.
  Future<Either<Failure, ProSubscription>> subscribe(String planId);

  /// `POST /v1/account/subscription/cancel` — stops the renewal; the paid
  /// period keeps running.
  Future<Either<Failure, ProSubscription>> cancel();

  /// `GET /v1/brands?page&limit` — public; the first page only (the paywall's
  /// brand logo rows, not a brand directory).
  Future<Either<Failure, List<BrandEntity>>> getBrands();
}
