import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/shop_entity.dart';
import '../repositories/discovery_repository.dart';

/// Load the `pick_up_page_main` feed: all shops sorted nearest-first, mirroring
/// Jameia's distance-sorted self-pickup list (`v2/homePage/pickUpShopList`).
class GetPickUpShopsUseCase implements UseCase<List<ShopEntity>, NoParams> {
  final DiscoveryRepository repository;
  const GetPickUpShopsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ShopEntity>>> call(NoParams params) async {
    final result = await repository.shops();
    return result.fold((failure) => Left(failure), (shops) {
      final sorted = List<ShopEntity>.of(shops)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return Right(List<ShopEntity>.unmodifiable(sorted));
    });
  }
}
