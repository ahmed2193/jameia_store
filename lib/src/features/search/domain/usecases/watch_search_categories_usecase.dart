import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../repositories/search_repository.dart';

/// The discover block of the store's top-level categories
/// (`GET /v1/categories`): the copy saved on the device first, then the
/// server's; failures on the error channel.
class WatchSearchCategoriesUseCase
    implements
        StreamUseCase<DataSnapshot<List<CatalogCategoryEntity>>, WatchParams> {
  const WatchSearchCategoriesUseCase(this._repository);

  final SearchRepository _repository;

  @override
  Stream<DataSnapshot<List<CatalogCategoryEntity>>> call(WatchParams params) =>
      _repository
          .watchCategoryTree(forceRefresh: params.forceRefresh)
          .map((snapshot) => snapshot.map((tree) => tree.roots));
}
