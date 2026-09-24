import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/recent_searches.dart';
import '../../domain/usecases/get_recent_searches_usecase.dart';
import '../../domain/usecases/get_search_discover_usecase.dart';
import '../../domain/usecases/save_recent_searches_usecase.dart';
import '../../domain/usecases/suggest_products_usecase.dart';
import 'search_state.dart';

/// The search tab: recent terms (device), discover blocks and live product
/// suggestions (backend). Typing is debounced here and a reply for text the
/// customer has already changed is dropped; nothing on this screen is
/// critical, so a failed request just leaves its block empty.
class SearchCubit extends Cubit<SearchState> with SafeCubitMixin<SearchState> {
  SearchCubit(
    this._getDiscover,
    this._suggestProducts,
    this._getRecents,
    this._saveRecents, {
    this._debounce = AppConstants.searchDebounce,
  }) : super(const SearchState());

  final GetSearchDiscoverUseCase _getDiscover;
  final SuggestProductsUseCase _suggestProducts;
  final GetRecentSearchesUseCase _getRecents;
  final SaveRecentSearchesUseCase _saveRecents;
  final Duration _debounce;

  Timer? _debounceTimer;

  /// Bumped by every keystroke; a suggestions reply of an older one is stale.
  int _generation = 0;

  /// Recents first (synchronous, from the device), then the backend blocks.
  Future<void> loadDiscover() async {
    safeEmit(
      state.copyWith(
        recents: _getRecents(const NoParams())
            .getOrElse(() => RecentSearches.empty),
      ),
    );
    final result = await _getDiscover(const NoParams());
    result.fold(
      (failure) => log('search discover failed: $failure', name: 'search'),
      (discover) => safeEmit(state.copyWith(discover: discover)),
    );
  }

  void onQueryChanged(String text) {
    _debounceTimer?.cancel();
    final generation = ++_generation;
    final tooShort = text.trim().length < SuggestProductsUseCase.minLength;
    safeEmit(
      state.copyWith(
        query: text,
        isSuggesting: !tooShort,
        suggestions: tooShort ? const <CatalogProductEntity>[] : null,
      ),
    );
    if (tooShort) return;
    _debounceTimer = Timer(_debounce, () => _suggest(text, generation));
  }

  Future<void> _suggest(String text, int generation) async {
    final result = await _suggestProducts(SuggestProductsParams(text));
    if (generation != _generation) return;
    safeEmit(
      state.copyWith(
        isSuggesting: false,
        suggestions: result.getOrElse(() => const <CatalogProductEntity>[]),
      ),
    );
  }

  /// The customer committed [term]: remember it (newest first).
  void addRecent(String term) => _storeRecents(state.recents.add(term));

  void clearRecents() => _storeRecents(RecentSearches.empty);

  void _storeRecents(RecentSearches recents) {
    if (recents == state.recents) return;
    safeEmit(state.copyWith(recents: recents));
    unawaited(_saveRecents(SaveRecentSearchesParams(recents)));
  }

  /// Back to the discover state (field cleared, or coming back from results).
  void clearQuery() {
    _debounceTimer?.cancel();
    _generation++;
    safeEmit(
      state.copyWith(
        query: '',
        suggestions: const <CatalogProductEntity>[],
        isSuggesting: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
