import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/recipes_feed.dart';
import '../../domain/usecases/get_recipes_usecase.dart';
import '../../domain/usecases/watch_recipes_usecase.dart';
import 'recipes_state.dart';

/// The recipe list (`GET /v1/recipes`), paginated. The first page paints
/// from the device copy (offline too), then the server's; the next pages
/// always come from the server. The screen and paging flow is the loader
/// mixins'.
class RecipesCubit extends Cubit<RecipesState>
    with
        SafeCubitMixin<RecipesState>,
        SnapshotLoaderMixin<RecipesState>,
        ScreenLoaderMixin<RecipesState>,
        PagedScreenMixin<RecipesState> {
  RecipesCubit(this._watchFirstPage, this._getRecipes)
    : super(const RecipesState());

  final WatchRecipesUseCase _watchFirstPage;
  final GetRecipesUseCase _getRecipes;

  Future<void> load() {
    showLoading();
    return _readFirstPage(WatchParams.cached);
  }

  /// Pull-to-refresh: the server's first page; the list stays meanwhile.
  @override
  Future<void> refresh() => _readFirstPage(WatchParams.fresh);

  Future<void> _readFirstPage(WatchParams params) => readScreen<RecipesFeed>(
    _watchFirstPage(params),
    show: (state, snapshot) => state.copyWith(feed: snapshot.data),
  );

  /// Called while scrolling near the end. After a failed page it waits for an
  /// explicit retry — or the connection to return — ([retry] = true) instead
  /// of hammering the backend.
  @override
  Future<void> loadMore({bool retry = false}) => loadNextPage<RecipesFeed>(
    hasMore: state.feed.hasMore,
    retry: retry,
    fetch: () => _getRecipes(GetRecipesParams(page: state.feed.page + 1)),
    merge: (state, next) => state.copyWith(feed: state.feed.merge(next)),
  );
}
