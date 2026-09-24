import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/region_options.dart';
import '../repositories/service_region_repository.dart';

/// The serviceable regions + the active region code (region picker).
class GetServiceRegionsUseCase implements UseCase<RegionOptions, NoParams> {
  const GetServiceRegionsUseCase(this._repository);

  final ServiceRegionRepository _repository;

  @override
  Future<Either<Failure, RegionOptions>> call(NoParams params) =>
      _repository.getServiceRegions();
}
