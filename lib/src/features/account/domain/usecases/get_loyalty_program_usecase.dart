import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/loyalty_program.dart';
import '../repositories/loyalty_repository.dart';

/// The store's loyalty programme (rates, minimum, bonuses).
class GetLoyaltyProgramUseCase implements UseCase<LoyaltyProgram, NoParams> {
  const GetLoyaltyProgramUseCase(this._repository);

  final LoyaltyRepository _repository;

  @override
  Future<Either<Failure, LoyaltyProgram>> call(NoParams params) =>
      _repository.getProgram();
}
