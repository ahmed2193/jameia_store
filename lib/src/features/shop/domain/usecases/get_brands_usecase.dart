import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/catalog_browse_repository.dart';

/// Loads the store's brands (`GET /v1/brands`).
class GetBrandsUseCase implements UseCase<List<BrandEntity>, NoParams> {
  const GetBrandsUseCase(this._repository);

  final CatalogBrowseRepository _repository;

  @override
  Future<Either<Failure, List<BrandEntity>>> call(NoParams params) =>
      _repository.getBrands();
}
