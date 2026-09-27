import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

/// Where the signed-in customer stands with Pro, from their subscription
/// (`GET /v1/account/subscription`): none → a prospect; otherwise renewing,
/// ending (cancelled, perks still on) or lapsed (see
/// [ProSubscription.membership]). A guest is `Left(UnauthorizedFailure)`.
class GetProMembershipUseCase
    implements UseCase<ProMembershipEntity, NoParams> {
  const GetProMembershipUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Future<Either<Failure, ProMembershipEntity>> call(NoParams params) async =>
      (await _repository.getSubscription()).map(
        (subscription) =>
            subscription?.membership ?? ProMembershipEntity.prospect,
      );
}
