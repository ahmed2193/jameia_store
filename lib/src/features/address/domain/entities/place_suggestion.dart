import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import 'pinned_place.dart';
import 'text_match.dart';

/// Who answered a place search. Google's answers must be credited on a
/// screen that shows no Google map ("Google Maps").
enum PlaceSource { google, geocoder, area }

/// One row of the place search: a name, where it is, how far.
/// [subtitle] is Google's line under the name, or a district's
/// governorate; a spot the geocoder found carries what the map reads there
/// ([place]).
class PlaceSuggestion extends Equatable {
  const PlaceSuggestion({
    required this.id,
    required this.title,
    required this.source,
    this.subtitle = '',
    this.titleMatches = const [],
    this.distanceMeters,
    this.location,
    this.place,
  });

  /// Google's place id, or a key of the answer's own for the others.
  final String id;
  final String title;
  final String subtitle;

  /// The parts of [title] that matched the words typed.
  final List<TextMatch> titleMatches;

  /// How far it is from where the map looks, when the search was told.
  final int? distanceMeters;

  /// The point, when the answer carried it; `null` = look it up first
  /// (`LocatePlaceUseCase`).
  final GeoPointEntity? location;

  /// What the map reads at [location] — a geocoder answer, read back: its
  /// street, block and area go under the name.
  final PinnedPlace? place;
  final PlaceSource source;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    titleMatches,
    distanceMeters,
    location,
    place,
    source,
  ];
}
