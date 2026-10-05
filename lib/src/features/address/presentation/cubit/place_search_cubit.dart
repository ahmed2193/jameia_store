import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/place_suggestion.dart';
import '../../domain/usecases/end_place_search_usecase.dart';
import '../../domain/usecases/get_delivery_areas_usecase.dart';
import '../../domain/usecases/locate_place_usecase.dart';
import '../../domain/usecases/search_places_usecase.dart';
import 'place_search_state.dart';

/// The place search (page-scoped): the districts Hero delivers to before
/// anything is typed ([showAreas]); then it asks [debounce] after the last
/// keystroke, keeps only the answer to the latest text, looks up the point
/// of a picked place once. Answers near where the map looks come first and
/// say how far they are. An answer's name can go back into the search box
/// ([fill]). Closing it ends the search session, so the next search starts
/// a new one.
class PlaceSearchCubit extends Cubit<PlaceSearchState>
    with SafeCubitMixin<PlaceSearchState> {
  PlaceSearchCubit({
    required this._searchPlaces,
    required this._locatePlace,
    required this._endSearch,
    required this._deliveryAreas,
    this._near,
  }) : super(const PlaceSearchState());

  final SearchPlacesUseCase _searchPlaces;
  final LocatePlaceUseCase _locatePlace;
  final EndPlaceSearchUseCase _endSearch;
  final GetDeliveryAreasUseCase _deliveryAreas;
  final GeoPointEntity? _near;

  static const Duration debounce = AppConstants.searchDebounce;

  Timer? _pending;
  int _generation = 0;
  String _languageCode = _defaultLanguage;

  static const String _defaultLanguage = 'en';

  /// Lists the districts Hero delivers to, in [languageCode].
  void showAreas({required String languageCode}) {
    _languageCode = languageCode;
    _deliveryAreas(DeliveryAreasParams(languageCode: languageCode, near: _near))
        .fold((_) {}, (areas) => safeEmit(state.copyWith(areas: areas)));
  }

  /// The customer tapped [suggestion]'s ↖: the search box takes its name
  /// ([PlaceSearchState.fill]) and the search asks again for it — unless
  /// those are the words already searched. Not while a picked place is
  /// looked up.
  void fill(PlaceSuggestion suggestion, {required String languageCode}) {
    if (state.lookingUpId != null) return;
    final words = suggestion.title;
    final searched = words.trim() == state.query;
    safeEmit(state.copyWith(fill: words));
    if (!searched) queryChanged(words, languageCode: languageCode);
  }

  /// The customer typed [text].
  void queryChanged(String text, {required String languageCode}) {
    _pending?.cancel();
    final generation = ++_generation;
    _languageCode = languageCode;
    final query = text.trim();
    if (query.length < SearchPlacesUseCase.minInputLength) {
      safeEmit(
        PlaceSearchState(
          query: query,
          lookingUpId: state.lookingUpId,
          areas: state.areas,
        ),
      );
      return;
    }
    safeEmit(state.copyWith(query: query, status: PlaceSearchStatus.loading));
    _pending = Timer(debounce, () => _search(query, languageCode, generation));
  }

  /// The search failed: ask again for the same text, now.
  void retry() {
    if (state.status != PlaceSearchStatus.failed) return;
    _pending?.cancel();
    final generation = ++_generation;
    safeEmit(state.copyWith(status: PlaceSearchStatus.loading));
    unawaited(_search(state.query, _languageCode, generation));
  }

  Future<void> _search(
    String query,
    String languageCode,
    int generation,
  ) async {
    final result = await _searchPlaces(
      SearchPlacesParams(input: query, languageCode: languageCode, near: _near),
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: PlaceSearchStatus.failed,
          suggestions: const [],
          failure: failure,
        ),
      ),
      (suggestions) => safeEmit(
        state.copyWith(
          status: suggestions.isEmpty
              ? PlaceSearchStatus.empty
              : PlaceSearchStatus.results,
          suggestions: suggestions,
        ),
      ),
    );
  }

  /// The customer picked [suggestion]: its point is looked up (once).
  Future<void> pick(
    PlaceSuggestion suggestion, {
    required String languageCode,
  }) async {
    if (state.lookingUpId != null) return;
    safeEmit(state.copyWith(lookingUpId: suggestion.id));
    final result = await _locatePlace(
      LocatePlaceParams(suggestion: suggestion, languageCode: languageCode),
    );
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(clearLookingUp: true, pickFailure: failure)),
      (spot) => safeEmit(state.copyWith(clearLookingUp: true, picked: spot)),
    );
  }

  @override
  Future<void> close() {
    _pending?.cancel();
    _endSearch(const NoParams());
    return super.close();
  }
}
