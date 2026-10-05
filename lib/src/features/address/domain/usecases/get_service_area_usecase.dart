import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/service_area.dart';
import '../repositories/service_area_repository.dart';

/// Where Hero delivers: the map checks the pin against it as it settles.
class GetServiceAreaUseCase implements UseCase<ServiceArea, NoParams> {
  const GetServiceAreaUseCase(this._repository);

  final ServiceAreaRepository _repository;

  @override
  Future<Either<Failure, ServiceArea>> call(NoParams params) =>
      _repository.serviceArea();
}
