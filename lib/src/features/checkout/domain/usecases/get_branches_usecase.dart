import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/branch_entity.dart';
import '../repositories/checkout_repository.dart';

/// Branches that offer pickup (the others cannot be chosen).
class GetBranchesUseCase implements UseCase<List<BranchEntity>, NoParams> {
  const GetBranchesUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, List<BranchEntity>>> call(NoParams params) async =>
      (await _repository.getBranches()).map(
        (branches) => [
          for (final branch in branches)
            if (branch.supportsPickup) branch,
        ],
      );
}
