import 'package:equatable/equatable.dart';

import 'place_spot.dart';

/// Where the address search sends the map picker: a place the customer
/// picked, or the device's own position.
sealed class MapDestination extends Equatable {
  const MapDestination();
}

/// A place picked from the search answers.
class PlaceDestination extends MapDestination {
  const PlaceDestination(this.spot);

  final PlaceSpot spot;

  @override
  List<Object?> get props => [spot];
}

/// "Use my current location".
class MyLocationDestination extends MapDestination {
  const MyLocationDestination();

  @override
  List<Object?> get props => const [];
}
