import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../entities/recipes_feed.dart';
import '../repositories/recipes_repository.dart';
import 'get_recipes_usecase.dart';

/// The first page of the recipe list (`GET /v1/recipes`), a page as long as
/// [GetRecipesUseCase]'s: the copy saved on the device first, then the
/// server's; failures on the error channel. The next pages are
/// [GetRecipesUseCase]'s — never kept.
class WatchRecipesUseCase
    implements StreamUseCase<DataSnapshot<RecipesFeed>, WatchParams> {
  const WatchRecipesUseCase(this._repository);

  final RecipesRepository _repository;

  @override
  Stream<DataSnapshot<RecipesFeed>> call(WatchParams params) =>
      _repository.watchRecipes(
        limit: GetRecipesParams.defaultPageSize,
        forceRefresh: params.forceRefresh,
      );
}
