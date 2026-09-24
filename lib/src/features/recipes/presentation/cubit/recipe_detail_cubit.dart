import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_recipe_detail_usecase.dart';
import 'recipe_detail_state.dart';

/// One recipe (`GET /v1/recipes/:slug`).
class RecipeDetailCubit extends Cubit<RecipeDetailState>
    with SafeCubitMixin<RecipeDetailState> {
  RecipeDetailCubit(this._getRecipeDetail, {required this._slug})
    : super(const RecipeDetailState());

  final GetRecipeDetailUseCase _getRecipeDetail;
  final String _slug;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: RecipeDetailStatus.loading));
    }
    final result = await _getRecipeDetail(GetRecipeDetailParams(_slug));
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? RecipeDetailStatus.loaded
              : RecipeDetailStatus.error,
          failure: failure,
        ),
      ),
      (detail) => safeEmit(
        state.copyWith(status: RecipeDetailStatus.loaded, detail: detail),
      ),
    );
  }
}
