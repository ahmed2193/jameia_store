import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/kingkong_landing_view.dart';
import '../entities/shop_entity.dart';
import '../repositories/discovery_repository.dart';

class GetKingKongLandingParams extends Equatable {
  const GetKingKongLandingParams(this.categoryId);

  /// KingKong item id from the tapped home icon — selects the base shop pool.
  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

/// Load the `homepage_kingkong_page` category landing: pick the base shop pool
/// by categoryId (food → restaurants, grocery/pharmacy/flowers → groceries,
/// else → all shops) and derive the sub-category chips from its distinct tags.
class GetKingKongLandingUseCase
    implements UseCase<KingKongLandingView, GetKingKongLandingParams> {
  final DiscoveryRepository repository;
  const GetKingKongLandingUseCase(this.repository);

  @override
  Future<Either<Failure, KingKongLandingView>> call(
    GetKingKongLandingParams params,
  ) async {
    final poolResult = switch (params.categoryId) {
      'k1' || 'k5' => await repository.restaurants(), // Food / Meal for One
      'k2' ||
      'k3' ||
      'k7' => await repository.groceries(), // Grocery / Pharmacy / Flowers
      _ => await repository.shops(),
    };
    return poolResult.fold(
      (failure) => Left(failure),
      (pool) => Right(
        KingKongLandingView(subCategories: _subCategories(pool), shops: pool),
      ),
    );
  }

  /// Distinct tag labels from [pool], preserving first-appearance order, with
  /// "All" always at index 0.
  static List<String> _subCategories(List<ShopEntity> pool) {
    final seen = <String>{};
    final tags = <String>['All'];
    for (final shop in pool) {
      for (final tag in shop.tags) {
        if (tag.isNotEmpty && seen.add(tag)) {
          tags.add(tag);
        }
      }
    }
    return tags;
  }
}
