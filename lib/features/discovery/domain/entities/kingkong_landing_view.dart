import 'package:equatable/equatable.dart';

import 'shop_entity.dart';

/// Loaded snapshot for the KeeTa `homepage_kingkong_page` category landing — the
/// derived sub-category chips and the category's base shop pool.
///
/// [GetKingKongLandingUseCase] picks the base pool by categoryId and derives the
/// sub-category labels; this immutable view then re-derives the per-chip shop
/// feed synchronously via [shopsForSub] as the user taps a chip.
class KingKongLandingView extends Equatable {
  const KingKongLandingView({required this.subCategories, required this.shops});

  /// Sub-category chips: "All" first, then the distinct base-pool tags in
  /// first-appearance order.
  final List<String> subCategories;

  /// The category's base shop pool (chip 0 = "All").
  final List<ShopEntity> shops;

  /// Shops for the sub-category chip at [sub].
  /// - index 0 → the full base pool
  /// - index N → shops whose [ShopEntity.tags] contain `subCategories[N]`
  ///   (case-insensitive).
  List<ShopEntity> shopsForSub(int sub) {
    if (sub == 0) return shops;
    final tag = subCategories[sub];
    return shops
        .where((s) => s.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [subCategories, shops];
}
