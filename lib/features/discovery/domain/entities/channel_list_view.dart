import 'package:equatable/equatable.dart';

import 'shop_entity.dart';

/// Loaded snapshot for the KeeTa `channel_list_main` landing — the derived scene
/// tabs, filter chips and the full shop pool the scene tabs filter.
///
/// The heavy build (deriving scene labels from shop tags) is done once by
/// [GetChannelListUseCase]; this immutable view then re-derives the per-scene
/// shop feed synchronously via [shopsForScene] as the user taps a tab (an async
/// use case cannot serve a tap).
class ChannelListView extends Equatable {
  const ChannelListView({
    required this.scenes,
    required this.filters,
    required this.shops,
  });

  /// Scene tabs across the top: "All" first, then every distinct shop tag.
  final List<String> scenes;

  /// Filter chips beneath the scene tabs (`filterId` / `filterDisplayName`).
  final List<String> filters;

  /// Full shop pool (scene 0 = "All").
  final List<ShopEntity> shops;

  /// Shops matching the scene tab at [scene].
  /// - index 0 → the full pool
  /// - index N → shops whose [ShopEntity.tags] contain `scenes[N]`
  List<ShopEntity> shopsForScene(int scene) {
    if (scene == 0) return shops;
    final tag = scenes[scene];
    return shops.where((s) => s.tags.contains(tag)).toList(growable: false);
  }

  @override
  List<Object?> get props => [scenes, filters, shops];
}
