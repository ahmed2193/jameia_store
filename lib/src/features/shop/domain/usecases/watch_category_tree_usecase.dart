import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../repositories/catalog_browse_repository.dart';

/// The whole category tree (`GET /v1/categories`): the copy saved on the
/// device first, then the server's; failures on the error channel.
class WatchCategoryTreeUseCase
    implements StreamUseCase<DataSnapshot<CatalogCategoryTree>, WatchParams> {
  const WatchCategoryTreeUseCase(this._repository);

  final CatalogBrowseRepository _repository;

  @override
  Stream<DataSnapshot<CatalogCategoryTree>> call(WatchParams params) =>
      _repository.watchCategoryTree(forceRefresh: params.forceRefresh);
}
