import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/fixed_price_view.dart';
import '../entities/shop_entity.dart';
import '../repositories/discovery_repository.dart';

class GetFixedPriceParams extends Equatable {
  const GetFixedPriceParams(this.shopId);

  /// Optional flash storefront id; null → pick the first grocery as the host.
  final String? shopId;

  @override
  List<Object?> get props => [shopId];
}

/// Load the fixed-price flash channel: resolve the host shop (the passed id, or
/// the first grocery, or the first shop) and sort its products so the discounted
/// lines lead the grid.
class GetFixedPriceUseCase
    implements UseCase<FixedPriceView, GetFixedPriceParams> {
  final DiscoveryRepository repository;
  const GetFixedPriceUseCase(this.repository);

  @override
  Future<Either<Failure, FixedPriceView>> call(
    GetFixedPriceParams params,
  ) async {
    final hostResult = params.shopId != null
        ? await repository.shopById(params.shopId!)
        : (await repository.shops()).fold(
            (failure) => Left<Failure, ShopEntity>(failure),
            (shops) => Right<Failure, ShopEntity>(_defaultHost(shops)),
          );
    return hostResult.fold((failure) => Left(failure), (shop) {
      final products = [...shop.allProducts]
        ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      return Right(FixedPriceView(shop: shop, products: products));
    });
  }

  /// The flash host when no id is passed: first grocery, else first shop.
  static ShopEntity _defaultHost(List<ShopEntity> shops) {
    final groceries = shops.where((s) => !s.isRestaurant);
    return groceries.isNotEmpty ? groceries.first : shops.first;
  }
}
