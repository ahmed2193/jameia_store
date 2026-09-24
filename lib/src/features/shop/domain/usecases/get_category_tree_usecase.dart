import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/catalog_browse_repository.dart';

class GetCategoryTreeParams extends Equatable {
  const GetCategoryTreeParams({this.refresh = false});

  /// A pull-to-refresh: ask the backend again instead of reusing the tree the
  /// app already holds.
  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

/// Loads the whole category tree (`GET /v1/categories`).
class GetCategoryTreeUseCase
    implements UseCase<CatalogCategoryTree, GetCategoryTreeParams> {
  const GetCategoryTreeUseCase(this._repository);

  final CatalogBrowseRepository _repository;

  @override
  Future<Either<Failure, CatalogCategoryTree>> call(
    GetCategoryTreeParams params,
  ) => _repository.getCategoryTree(refresh: params.refresh);
}
