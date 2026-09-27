import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recipe_detail.dart';
import '../repositories/recipes_repository.dart';

class WatchRecipeDetailParams extends Equatable {
  const WatchRecipeDetailParams(this.slug, {this.forceRefresh = false});

  final String slug;

  /// The page asks the server again (reconnect): skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [slug, forceRefresh];
}

/// A recipe page (`GET /v1/recipes/:slug`): the copy saved on the device
/// first, then the server's; failures on the error channel.
class WatchRecipeDetailUseCase
    implements
        StreamUseCase<DataSnapshot<RecipeDetail>, WatchRecipeDetailParams> {
  const WatchRecipeDetailUseCase(this._repository);

  final RecipesRepository _repository;

  @override
  Stream<DataSnapshot<RecipeDetail>> call(WatchRecipeDetailParams params) =>
      _repository.watchRecipe(params.slug, forceRefresh: params.forceRefresh);
}
