import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recipe_detail.dart';
import '../repositories/recipes_repository.dart';

class GetRecipeDetailParams extends Equatable {
  const GetRecipeDetailParams(this.slug);

  final String slug;

  @override
  List<Object?> get props => [slug];
}

/// Loads a recipe page (`GET /v1/recipes/:slug`).
class GetRecipeDetailUseCase
    implements UseCase<RecipeDetail, GetRecipeDetailParams> {
  const GetRecipeDetailUseCase(this._repository);

  final RecipesRepository _repository;

  @override
  Future<Either<Failure, RecipeDetail>> call(GetRecipeDetailParams params) =>
      _repository.getRecipe(params.slug);
}
