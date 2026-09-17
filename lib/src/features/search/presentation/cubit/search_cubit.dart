import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/entities/shop_sort.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_usecase.dart';

enum SearchStatus { initial, loading, loaded, empty, error }

/// Single immutable state for the global search feature. Serves BOTH the
/// discover/type-ahead screen (`c_search`) and the sort/filter results screen
/// (`c_search_shop`) — each gets its own factory instance:
///
/// • discover: [hotWords] + [recent] rendered on the empty-query landing;
///   [results] is the live type-ahead preview for a non-empty [query].
/// • results: [query] is the committed term; [sort] + [freeOnly] drive the
///   filtered/sorted [results].
///
/// Purely-ephemeral UI (text controller, focus, history expand/fold) stays in
/// the screens.
class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.brands = const [],
    this.suggestions = const [],
    this.recent = const [],
    this.hotWords = const [],
    this.sort = ShopSort.recommended,
    this.freeOnly = false,
    this.error,
  });

  final SearchStatus status;

  /// The active query (type-ahead or committed). Empty → discover landing.
  final String query;

  /// Matching shops for [query] (already sorted/filtered per [sort]/[freeOnly]).
  final List<ShopEntity> results;

  /// Popular-brands strip for the discover landing (catalogue shops with a logo).
  final List<ShopEntity> brands;

  /// Type-ahead completions shown while the user is typing (before a query is
  /// committed / a suggestion is tapped).
  final List<String> suggestions;

  /// Persisted recent searches, most-recent first (discover landing).
  final List<String> recent;

  /// Hot-word chips for the discover landing.
  final List<String> hotWords;

  /// Results-page sort mode.
  final ShopSort sort;

  /// Results-page free-delivery filter.
  final bool freeOnly;

  final String? error;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<ShopEntity>? results,
    List<ShopEntity>? brands,
    List<String>? suggestions,
    List<String>? recent,
    List<String>? hotWords,
    ShopSort? sort,
    bool? freeOnly,
    String? error,
  }) => SearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    results: results ?? this.results,
    brands: brands ?? this.brands,
    suggestions: suggestions ?? this.suggestions,
    recent: recent ?? this.recent,
    hotWords: hotWords ?? this.hotWords,
    sort: sort ?? this.sort,
    freeOnly: freeOnly ?? this.freeOnly,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    query,
    results,
    brands,
    suggestions,
    recent,
    hotWords,
    sort,
    freeOnly,
    error,
  ];
}

/// Page-scoped cubit — resolved via `sl<SearchCubit>()` (fresh factory instance
/// per screen). The discover screen calls [loadDiscover] on provide; the results
/// screen calls [startResults]. Type-ahead search is [AppConstants.searchDebounce]
/// debounced so `searchShops` is not re-run on every keystroke.
class SearchCubit extends Cubit<SearchState> with SafeCubitMixin<SearchState> {
  SearchCubit({
    required SearchUseCase search,
    required SearchRepository repository,
  }) : _search = search,
       _repository = repository,
       super(const SearchState());

  final SearchUseCase _search;
  final SearchRepository _repository;

  Timer? _debounce;

  /// Load the discover landing (hot words + persisted recents + popular brands)
  /// — the discover screen expects these on first build.
  Future<void> loadDiscover() async {
    safeEmit(state.copyWith(status: SearchStatus.loading));
    final hot = await _repository.hotWords();
    final rec = await _repository.recentSearches();
    final brandsRes = await _repository.popularBrands();
    final hotWords = hot.getOrElse(() => const []);
    final recent = rec.getOrElse(() => const []);
    final brands = brandsRes.getOrElse(() => const []);
    safeEmit(
      state.copyWith(
        status: SearchStatus.loaded,
        hotWords: hotWords,
        recent: recent,
        brands: brands,
      ),
    );
  }

  /// Seed the results screen with the committed [query] and run the first
  /// search immediately (no debounce).
  Future<void> startResults(String query) async {
    safeEmit(state.copyWith(status: SearchStatus.loading, query: query));
    await runSearch(query);
  }

  /// Debounced type-ahead — called on every keystroke. While the user is typing
  /// we surface [suggestions] (not full results); results are committed on
  /// submit / suggestion tap ([runSearch]). An empty field returns to discover.
  void onQueryChanged(String raw) {
    _debounce?.cancel();
    if (raw.trim().isEmpty) {
      _resetToDiscover();
      return;
    }
    // Reflect the typed query immediately and drop any stale results so the
    // active surface shows the suggestion phase; suggestions arrive on debounce.
    safeEmit(
      state.copyWith(
        status: SearchStatus.loaded,
        query: raw,
        results: const [],
      ),
    );
    _debounce = Timer(AppConstants.searchDebounce, () async {
      final res = await _repository.getSuggestions(raw);
      safeEmit(state.copyWith(suggestions: res.getOrElse(() => const [])));
    });
  }

  /// Commit [query] — run the shop search with the current sort/filter and fold
  /// the matching shops (each carrying its own products) into the state.
  Future<void> runSearch(String query) async {
    _debounce?.cancel();
    safeEmit(
      state.copyWith(
        status: SearchStatus.loading,
        query: query,
        suggestions: const [],
      ),
    );
    final shopsRes = await _search(
      SearchParams(query: query, sort: state.sort, freeOnly: state.freeOnly),
    );
    shopsRes.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: SearchStatus.error,
          query: query,
          error: failure.message,
        ),
      ),
      (shops) => safeEmit(
        state.copyWith(
          status: shops.isEmpty ? SearchStatus.empty : SearchStatus.loaded,
          query: query,
          results: shops,
          suggestions: const [],
        ),
      ),
    );
  }

  /// Change the results-page sort mode and re-run the search.
  Future<void> setSort(ShopSort sort) async {
    if (sort == state.sort) return;
    safeEmit(state.copyWith(sort: sort));
    await runSearch(state.query);
  }

  /// Toggle the results-page free-delivery filter and re-run the search.
  Future<void> toggleFreeOnly() async {
    safeEmit(state.copyWith(freeOnly: !state.freeOnly));
    await runSearch(state.query);
  }

  /// Record a committed term into the persisted recents (dedup + cap).
  Future<void> addRecent(String term) async {
    final result = await _repository.addRecentSearch(term);
    result.fold((_) {}, (recent) => safeEmit(state.copyWith(recent: recent)));
  }

  /// Clear the persisted recent searches.
  Future<void> clearRecent() async {
    final result = await _repository.clearRecentSearches();
    result.fold((_) {}, (recent) => safeEmit(state.copyWith(recent: recent)));
  }

  /// Clear the active query → return to the discover landing.
  void clearQuery() {
    _debounce?.cancel();
    _resetToDiscover();
  }

  /// Collapse the active-search surface back to discover (clears query,
  /// suggestions and results). Used when the search field is closed.
  void clearActiveResults() {
    _debounce?.cancel();
    _resetToDiscover();
  }

  void _resetToDiscover() => safeEmit(
    state.copyWith(
      status: SearchStatus.loaded,
      query: '',
      results: const [],
      suggestions: const [],
    ),
  );

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
