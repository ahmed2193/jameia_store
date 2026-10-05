import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/place_suggestion.dart';
import '../repositories/places_repository.dart';

class DeliveryAreasParams extends Equatable {
  const DeliveryAreasParams({required this.languageCode, this.near});

  final String languageCode;

  /// Where the map looks: each district says how far it is from there.
  final GeoPointEntity? near;

  @override
  List<Object?> get props => [languageCode, near];
}

/// The districts Hero delivers to, A to Z in the customer's language: the
/// search shows them before anything is typed, so a pin outside Kuwait
/// finds its way back with one tap (jm3eia_mobile's "choose from the
/// list").
class GetDeliveryAreasUseCase
    implements SyncUseCase<List<PlaceSuggestion>, DeliveryAreasParams> {
  const GetDeliveryAreasUseCase(this._places);

  final PlacesRepository _places;

  @override
  Either<Failure, List<PlaceSuggestion>> call(DeliveryAreasParams params) =>
      _places.deliveryAreas(
        languageCode: params.languageCode,
        near: params.near,
      );
}
