import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/place_suggestion.dart';
import '../entities/service_area.dart';
import '../repositories/places_repository.dart';
import '../repositories/service_area_repository.dart';

class SearchPlacesParams extends Equatable {
  const SearchPlacesParams({
    required this.input,
    required this.languageCode,
    this.near,
  });

  final String input;
  final String languageCode;

  /// Where the map looks: nearer places rank first.
  final GeoPointEntity? near;

  @override
  List<Object?> get props => [input, languageCode, near];
}

/// Places matching what the customer typed, where Hero delivers: an answer
/// whose point lies outside the delivery area is never offered (one with no
/// point yet — Google's, looked up when picked — is checked by the map).
/// Fewer than [minInputLength] characters ask nothing of the network: no
/// place is found by one letter.
class SearchPlacesUseCase
    implements UseCase<List<PlaceSuggestion>, SearchPlacesParams> {
  const SearchPlacesUseCase(this._places, this._serviceArea);

  static const int minInputLength = 2;

  final PlacesRepository _places;
  final ServiceAreaRepository _serviceArea;

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> call(
    SearchPlacesParams params,
  ) async {
    final input = params.input.trim();
    if (input.length < minInputLength) {
      return const Right(<PlaceSuggestion>[]);
    }
    final found = await _places.suggest(
      input,
      languageCode: params.languageCode,
      near: params.near,
    );
    final area = (await _serviceArea.serviceArea()).fold(
      (_) => null,
      (area) => area,
    );
    if (area == null) return found;
    return found.map(
      (answers) => [
        for (final answer in answers)
          if (_delivered(answer, area)) answer,
      ],
    );
  }

  static bool _delivered(PlaceSuggestion answer, ServiceArea area) {
    final point = answer.location;
    return point == null || area.contains(point);
  }
}
