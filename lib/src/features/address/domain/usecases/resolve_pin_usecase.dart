import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pinned_place.dart';
import '../repositories/places_repository.dart';

class ResolvePinParams extends Equatable {
  const ResolvePinParams({required this.point, required this.languageCode});

  final GeoPointEntity point;
  final String languageCode;

  @override
  List<Object?> get props => [point, languageCode];
}

/// What the map pin points at (the street-level parts of the address).
class ResolvePinUseCase implements UseCase<PinnedPlace, ResolvePinParams> {
  const ResolvePinUseCase(this._repository);

  final PlacesRepository _repository;

  @override
  Future<Either<Failure, PinnedPlace>> call(ResolvePinParams params) =>
      _repository.resolve(params.point, languageCode: params.languageCode);
}
