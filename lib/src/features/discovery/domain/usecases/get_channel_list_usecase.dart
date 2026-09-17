import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/channel_list_view.dart';
import '../entities/shop_entity.dart';
import '../repositories/discovery_repository.dart';

/// Load the `channel_list_main` landing: derive the scene tabs from the distinct
/// shop tags ("All" first) and pair them with the real filter chips + shop pool.
class GetChannelListUseCase implements UseCase<ChannelListView, NoParams> {
  final DiscoveryRepository repository;
  const GetChannelListUseCase(this.repository);

  @override
  Future<Either<Failure, ChannelListView>> call(NoParams params) async {
    final result = await repository.catalogue();
    return result.fold(
      (failure) => Left(failure),
      (c) => Right(
        ChannelListView(
          scenes: _scenes(c.shops),
          filters: c.filters,
          shops: c.shops,
        ),
      ),
    );
  }

  /// Scene-tab list: "All" first, then every distinct tag that appears on at
  /// least one shop, in insertion order.
  static List<String> _scenes(List<ShopEntity> shops) {
    final seen = <String>{};
    for (final shop in shops) {
      for (final tag in shop.tags) {
        seen.add(tag);
      }
    }
    return ['All', ...seen];
  }
}
