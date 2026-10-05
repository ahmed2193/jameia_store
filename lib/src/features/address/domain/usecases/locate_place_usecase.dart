import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/place_spot.dart';
import '../entities/place_suggestion.dart';
import '../repositories/places_repository.dart';

class LocatePlaceParams extends Equatable {
  const LocatePlaceParams({
    required this.suggestion,
    required this.languageCode,
  });

  final PlaceSuggestion suggestion;
  final String languageCode;

  @override
  List<Object?> get props => [suggestion, languageCode];
}

/// Where a picked search answer is: the map's next stop.
class LocatePlaceUseCase implements UseCase<PlaceSpot, LocatePlaceParams> {
  const LocatePlaceUseCase(this._repository);

  final PlacesRepository _repository;

  @override
  Future<Either<Failure, PlaceSpot>> call(LocatePlaceParams params) =>
      _repository.locate(params.suggestion, languageCode: params.languageCode);
}
