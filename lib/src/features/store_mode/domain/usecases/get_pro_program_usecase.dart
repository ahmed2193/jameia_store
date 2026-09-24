import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pro_membership.dart';
import '../repositories/pro_membership_repository.dart';

/// Loads the Pro programme — perks + plans (`GET /v1/subscription-plans`).
class GetProProgramUseCase implements UseCase<ProProgram, NoParams> {
  const GetProProgramUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Future<Either<Failure, ProProgram>> call(NoParams params) =>
      _repository.getProgram();
}
