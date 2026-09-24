import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_recipes_usecase.dart';
import 'recipes_state.dart';

/// The recipe list (`GET /v1/recipes`), paginated.
class RecipesCubit extends Cubit<RecipesState>
    with SafeCubitMixin<RecipesState> {
  RecipesCubit(this._getRecipes) : super(const RecipesState());

  static const int _firstPage = 1;

  final GetRecipesUseCase _getRecipes;

  /// Bumped by every first-page load; an older reply is stale.
  int _generation = 0;

  Future<void> load() async {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: RecipesStatus.loading));
    }
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getRecipes(const GetRecipesParams(page: _firstPage));
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded ? RecipesStatus.loaded : RecipesStatus.error,
          failure: failure,
        ),
      ),
      (feed) => safeEmit(
        state.copyWith(
          status: RecipesStatus.loaded,
          feed: feed,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      ),
    );
  }

  /// Called while scrolling near the end. After a failed page it waits for an
  /// explicit retry ([retry] = true) instead of hammering the backend.
  Future<void> loadMore({bool retry = false}) async {
    if (!state.canLoadMore || (state.loadMoreFailed && !retry)) return;
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getRecipes(
      GetRecipesParams(page: state.feed.page + 1),
    );
    if (generation != _generation) {
      safeEmit(state.copyWith(isLoadingMore: false));
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
          failure: failure,
        ),
      ),
      (next) => safeEmit(
        state.copyWith(isLoadingMore: false, feed: state.feed.merge(next)),
      ),
    );
  }
}
