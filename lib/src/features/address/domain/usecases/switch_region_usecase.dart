import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/service_region_repository.dart';

class SwitchRegionParams extends Equatable {
  const SwitchRegionParams({required this.region});

  /// Two-letter region code.
  final String region;

  @override
  List<Object?> get props => [region];
}

/// Commits a region switch from the region picker.
class SwitchRegionUseCase implements UseCase<Unit, SwitchRegionParams> {
  const SwitchRegionUseCase(this._repository);

  final ServiceRegionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SwitchRegionParams params) =>
      _repository.switchRegion(params.region);
}
