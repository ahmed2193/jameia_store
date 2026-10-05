import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';

/// A place the customer picked from the search, with its point: where the
/// map goes next.
class PlaceSpot extends Equatable {
  const PlaceSpot({
    required this.location,
    required this.title,
    this.isArea = false,
  });

  final GeoPointEntity location;

  /// What the pin goes by while it stays on the place.
  final String title;

  /// A whole district: the map shows its streets, not one door.
  final bool isArea;

  @override
  List<Object?> get props => [location, title, isArea];
}
