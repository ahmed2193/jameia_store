import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

/// Stops the renewal of the customer's Pro subscription
/// (`POST /v1/account/subscription/cancel`); the paid period keeps running.
class CancelProSubscriptionUseCase
    implements UseCase<ProSubscription, NoParams> {
  const CancelProSubscriptionUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Future<Either<Failure, ProSubscription>> call(NoParams params) =>
      _repository.cancel();
}
