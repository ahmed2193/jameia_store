import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/search_discover.dart';
import '../repositories/search_repository.dart';

/// Loads the discover blocks of the search screen — top-level categories
/// (`GET /v1/categories`) and brands (`GET /v1/brands`) — side by side. One
/// block failing leaves the other; only when BOTH fail is it a failure.
class GetSearchDiscoverUseCase implements UseCase<SearchDiscover, NoParams> {
  const GetSearchDiscoverUseCase(this._repository);

  final SearchRepository _repository;

  @override
  Future<Either<Failure, SearchDiscover>> call(NoParams params) async {
    final (tree, brands) = await (
      _repository.getCategoryTree(),
      _repository.getBrands(),
    ).wait;
    if (tree.isLeft() && brands.isLeft()) {
      return tree.map((_) => SearchDiscover.empty);
    }
    return Right(
      SearchDiscover(
        categories: tree.fold(
          (_) => const <CatalogCategoryEntity>[],
          (loaded) => loaded.roots,
        ),
        brands: brands.getOrElse(() => const <BrandEntity>[]),
      ),
    );
  }
}
