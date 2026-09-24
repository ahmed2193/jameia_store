import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

/// Loads the customer's Pro subscription (`GET /v1/account/subscription`):
/// `Right(null)` = none, `Left(UnauthorizedFailure)` = not signed in.
class GetProSubscriptionUseCase implements UseCase<ProSubscription?, NoParams> {
  const GetProSubscriptionUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Future<Either<Failure, ProSubscription?>> call(NoParams params) =>
      _repository.getSubscription();
}
