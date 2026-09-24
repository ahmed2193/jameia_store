import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recipes_feed.dart';
import '../repositories/recipes_repository.dart';

class GetRecipesParams extends Equatable {
  const GetRecipesParams({required this.page, this.limit = defaultPageSize});

  static const int defaultPageSize = 20;

  /// 1-based.
  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

/// Loads one page of recipes (`GET /v1/recipes`).
class GetRecipesUseCase implements UseCase<RecipesFeed, GetRecipesParams> {
  const GetRecipesUseCase(this._repository);

  final RecipesRepository _repository;

  @override
  Future<Either<Failure, RecipesFeed>> call(GetRecipesParams params) =>
      _repository.getRecipes(page: params.page, limit: params.limit);
}
