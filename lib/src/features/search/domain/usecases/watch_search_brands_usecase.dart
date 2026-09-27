import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../repositories/search_repository.dart';

/// The discover block of the store's brands (`GET /v1/brands`): the copy
/// saved on the device first, then the server's; failures on the error
/// channel.
class WatchSearchBrandsUseCase
    implements StreamUseCase<DataSnapshot<List<BrandEntity>>, WatchParams> {
  const WatchSearchBrandsUseCase(this._repository);

  final SearchRepository _repository;

  @override
  Stream<DataSnapshot<List<BrandEntity>>> call(WatchParams params) =>
      _repository.watchBrands(forceRefresh: params.forceRefresh);
}
