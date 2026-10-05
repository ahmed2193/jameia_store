import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/place_spot.dart';
import '../../domain/entities/place_suggestion.dart';

enum PlaceSearchStatus {
  /// Nothing typed yet (or too little to search).
  idle,

  /// Looking: the last answers stay up, dimmed.
  loading,
  results,
  empty,

  /// The search failed and nothing else matched ([PlaceSearchState.failure]).
  failed,
}

/// The place search over the map: what was typed and what matched.
class PlaceSearchState extends Equatable {
  const PlaceSearchState({
    this.query = '',
    this.status = PlaceSearchStatus.idle,
    this.suggestions = const [],
    this.failure,
    this.lookingUpId,
    this.picked,
    this.pickFailure,
    this.areas = const [],
    this.fill,
  });

  final String query;
  final PlaceSearchStatus status;
  final List<PlaceSuggestion> suggestions;

  /// Why the search failed: kept while the status says
  /// [PlaceSearchStatus.failed], gone with any other status.
  final Failure? failure;

  /// The id of the answer whose point is being looked up (its row shows a
  /// loader).
  final String? lookingUpId;

  /// Transient: the place picked — the map flies there. Cleared on every
  /// [copyWith].
  final PlaceSpot? picked;

  /// Transient: the picked place could not be looked up.
  final Failure? pickFailure;

  /// The districts Hero delivers to, A to Z: shown before anything is typed.
  final List<PlaceSuggestion> areas;

  /// Transient: words the search box takes (an answer's ↖). Cleared on
  /// every [copyWith].
  final String? fill;

  /// Google answered: the list must say "Google Maps".
  bool get creditsGoogle =>
      suggestions.any((answer) => answer.source == PlaceSource.google);

  PlaceSearchState copyWith({
    String? query,
    PlaceSearchStatus? status,
    List<PlaceSuggestion>? suggestions,
    Failure? failure,
    String? lookingUpId,
    bool clearLookingUp = false,
    PlaceSpot? picked,
    Failure? pickFailure,
    List<PlaceSuggestion>? areas,
    String? fill,
  }) {
    final next = status ?? this.status;
    return PlaceSearchState(
      query: query ?? this.query,
      status: next,
      suggestions: suggestions ?? this.suggestions,
      failure: next == PlaceSearchStatus.failed
          ? failure ?? this.failure
          : null,
      lookingUpId: clearLookingUp ? null : lookingUpId ?? this.lookingUpId,
      picked: picked,
      pickFailure: pickFailure,
      areas: areas ?? this.areas,
      fill: fill,
    );
  }

  @override
  List<Object?> get props => [
    query,
    status,
    suggestions,
    failure,
    lookingUpId,
    picked,
    pickFailure,
    areas,
    fill,
  ];
}
