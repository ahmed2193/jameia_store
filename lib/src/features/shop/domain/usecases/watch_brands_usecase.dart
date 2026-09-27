import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../repositories/catalog_browse_repository.dart';

/// The store's brands (`GET /v1/brands`): the copy saved on the device first,
/// then the server's; failures on the error channel.
class WatchBrandsUseCase
    implements StreamUseCase<DataSnapshot<List<BrandEntity>>, WatchParams> {
  const WatchBrandsUseCase(this._repository);

  final CatalogBrowseRepository _repository;

  @override
  Stream<DataSnapshot<List<BrandEntity>>> call(WatchParams params) =>
      _repository.watchBrands(forceRefresh: params.forceRefresh);
}
