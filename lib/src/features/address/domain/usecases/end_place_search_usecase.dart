import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/places_repository.dart';

/// The search closed without a pick: the next one is a new session.
class EndPlaceSearchUseCase implements SyncUseCase<Unit, NoParams> {
  const EndPlaceSearchUseCase(this._repository);

  final PlacesRepository _repository;

  @override
  Either<Failure, Unit> call(NoParams params) => _repository.endSearch();
}
