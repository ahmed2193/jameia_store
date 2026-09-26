import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/pro_membership_repository.dart';

/// Loads the brands the Pro paywall shows in its logo rows
/// (`GET /v1/brands`, first page).
class GetProBrandsUseCase implements UseCase<List<BrandEntity>, NoParams> {
  const GetProBrandsUseCase(this._repository);

  final ProMembershipRepository _repository;

  @override
  Future<Either<Failure, List<BrandEntity>>> call(NoParams params) =>
      _repository.getBrands();
}
