import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

class SubscribeToProParams extends Equatable {
  const SubscribeToProParams(this.planId);

  final String planId;

  @override
  List<Object?> get props => [planId];
}

/// Subscribes the customer to a Pro plan
/// (`POST /v1/account/subscription { planId }`).
class SubscribeToProUseCase
    implements UseCase<ProSubscription, SubscribeToProParams> {
  const SubscribeToProUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Future<Either<Failure, ProSubscription>> call(
    SubscribeToProParams params,
  ) async {
    if (params.planId.isEmpty) {
      return const Left(UnexpectedFailure('pro: plan id missing'));
    }
    return _repository.subscribe(params.planId);
  }
}
