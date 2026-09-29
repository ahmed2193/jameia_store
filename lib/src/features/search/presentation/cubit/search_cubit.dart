import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/recent_searches.dart';
import '../../domain/usecases/get_recent_searches_usecase.dart';
import '../../domain/usecases/save_recent_searches_usecase.dart';
import '../../domain/usecases/suggest_products_usecase.dart';
import '../../domain/usecases/watch_search_brands_usecase.dart';
import '../../domain/usecases/watch_search_categories_usecase.dart';
import 'search_state.dart';

/// The search tab: recent terms (device), discover blocks (the device copy
/// first, then the backend) and live product suggestions (backend). Typing
/// is debounced here and a reply for text the customer has already changed
/// is dropped. A discover block that cannot load simply does not show — but
/// while neither has anything yet the screen shows their skeleton, and when
/// both failed with nothing saved it keeps the reason (the failure view); a
/// suggestions request that fails keeps its reason for the list.
class SearchCubit extends Cubit<SearchState>
    with SafeCubitMixin<SearchState>, SnapshotLoaderMixin<SearchState> {
  SearchCubit(
    this._watchCategories,
    this._watchBrands,
    this._suggestProducts,
    this._getRecents,
    this._saveRecents, {
    this._debounce = AppConstants.searchDebounce,
  }) : super(const SearchState());

  static const Object _categoriesChannel = #categories;
  static const Object _brandsChannel = #brands;
  static const String _logName = 'search';

  final WatchSearchCategoriesUseCase _watchCategories;
  final WatchSearchBrandsUseCase _watchBrands;
  final SuggestProductsUseCase _suggestProducts;
  final GetRecentSearchesUseCase _getRecents;
  final SaveRecentSearchesUseCase _saveRecents;
  final Duration _debounce;

  Timer? _debounceTimer;

  /// Bumped by every keystroke; a suggestions reply of an older one is stale.
  int _generation = 0;

  /// Bumped by every discover read; only the newest one settles the state.
  int _discoverGeneration = 0;

  /// The discover blocks showing a saved copy, or none after a failure: the
  /// ones a reconnect refreshes.
  final Set<Object> _staleBlocks = <Object>{};

  /// Recents first (synchronous, from the device), then the discover blocks.
  Future<void> loadDiscover() {
    safeEmit(
      state.copyWith(
        recents: _getRecents(const NoParams())
            .getOrElse(() => RecentSearches.empty),
      ),
    );
    return _readDiscover(WatchParams.cached);
  }

  /// The connection came back: the discover blocks refresh when they show a
  /// saved copy or failed, and suggestions that failed offline load for the
  /// text as it is now.
  Future<void> onReconnected() {
    if (state.isTyping && state.suggestFailure != null) {
      onQueryChanged(state.query);
    }
    return refreshOnReconnect(
      needed: () => _staleBlocks.isNotEmpty,
      refresh: () => _readDiscover(WatchParams.fresh),
    );
  }

  Future<void> _readDiscover(WatchParams params) async {
    final generation = ++_discoverGeneration;
    Failure? failed;
    safeEmit(
      state.copyWith(
        isDiscoverLoading: state.discover.isEmpty,
        clearDiscoverFailure: true,
      ),
    );
    await _followDiscover(params, onFailure: (failure) => failed = failure);
    if (generation != _discoverGeneration) return;
    final nothing = state.discover.isEmpty;
    safeEmit(
      state.copyWith(
        isDiscoverLoading: false,
        discoverFailure: nothing ? failed : null,
        clearDiscoverFailure: !nothing || failed == null,
      ),
    );
  }

  Future<void> _followDiscover(
    WatchParams params, {
    required void Function(Failure failure) onFailure,
  }) => Future.wait([
    followSnapshots(
      _watchCategories(params),
      channel: _categoriesChannel,
      onSnapshot: (snapshot) {
        _markBlock(_categoriesChannel, snapshot);
        safeEmit(
          state.copyWith(
            discover: state.discover.copyWith(categories: snapshot.data),
            isDiscoverLoading: false,
          ),
        );
      },
      onFailure: (failure) {
        onFailure(failure);
        _blockFailed(_categoriesChannel, failure);
      },
    ),
    followSnapshots(
      _watchBrands(params),
      channel: _brandsChannel,
      onSnapshot: (snapshot) {
        _markBlock(_brandsChannel, snapshot);
        safeEmit(
          state.copyWith(
            discover: state.discover.copyWith(brands: snapshot.data),
            isDiscoverLoading: false,
          ),
        );
      },
      onFailure: (failure) {
        onFailure(failure);
        _blockFailed(_brandsChannel, failure);
      },
    ),
  ]);

  void _markBlock(Object block, DataSnapshot<Object?> snapshot) =>
      snapshot.isFromCache
      ? _staleBlocks.add(block)
      : _staleBlocks.remove(block);

  void _blockFailed(Object block, Failure failure) {
    _staleBlocks.add(block);
    log('search discover $block failed: $failure', name: _logName);
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
        clearSuggestFailure: true,
      ),
    );
    if (tooShort) return;
    _debounceTimer = Timer(_debounce, () => _suggest(text, generation));
  }

  Future<void> _suggest(String text, int generation) async {
    final result = await _suggestProducts(SuggestProductsParams(text));
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isSuggesting: false,
          suggestions: const <CatalogProductEntity>[],
          suggestFailure: failure,
        ),
      ),
      (suggestions) => safeEmit(
        state.copyWith(
          isSuggesting: false,
          suggestions: suggestions,
          clearSuggestFailure: true,
        ),
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
        clearSuggestFailure: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
