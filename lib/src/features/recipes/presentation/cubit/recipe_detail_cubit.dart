import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/recipe_detail.dart';
import '../../domain/usecases/watch_recipe_detail_usecase.dart';
import 'recipe_detail_state.dart';

/// One recipe (`GET /v1/recipes/:slug`): the device copy first (offline
/// too), then the server's; the screen flow is the loader mixins' (a recipe
/// that does not exist stays "not found" on reconnect).
class RecipeDetailCubit extends Cubit<RecipeDetailState>
    with
        SafeCubitMixin<RecipeDetailState>,
        SnapshotLoaderMixin<RecipeDetailState>,
        ScreenLoaderMixin<RecipeDetailState> {
  RecipeDetailCubit(this._watchRecipe, {required this._slug})
    : super(const RecipeDetailState());

  final WatchRecipeDetailUseCase _watchRecipe;
  final String _slug;

  /// First load, retry, language switch; a recipe on screen stays meanwhile.
  Future<void> load() {
    showLoading();
    return _read(forceRefresh: false);
  }

  /// The server's recipe (the reconnect refresh of a saved or failed one).
  @override
  Future<void> refresh() => _read(forceRefresh: true);

  Future<void> _read({required bool forceRefresh}) => readScreen<RecipeDetail>(
    _watchRecipe(WatchRecipeDetailParams(_slug, forceRefresh: forceRefresh)),
    show: (state, snapshot) => state.copyWith(detail: snapshot.data),
  );
}
