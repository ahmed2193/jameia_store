import 'package:dartz/dartz.dart';

import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../entities/shop_entity.dart';

/// Read boundary for the shop feature. Offline, every method resolves from the
/// in-memory catalogue via the local data source.
///
/// The self-contained shop-detail panel returns a framework-free [ShopEntity].
/// Two surfaces deliberately stay in CORE DTOs (P2.9 boundary rule):
///   • [getFavoriteShops] feeds the shared `ShopCard` core widget (which takes
///     the core `Shop`), so the favourites list is kept as `Shop`.
///   • [shopById] / [categoryById] feed the synchronous shop-menu screen, whose
///     product rows push the core `Product` into the cart / product-details
///     features — so the menu graph stays in core `Shop` / `JameiaCategory`.
abstract class ShopRepository {
  /// One [ShopEntity] for the read-only shop-detail panel (`shop_detail`,
  /// bundle 48).
  Future<Either<Failure, ShopEntity>> getShopDetail(String shopId);

  /// The user's favourited shops (`shop_favorites`, bundle 49). Offline this is
  /// the whole catalogue standing in for "favourites".
  ///
  /// TODO(P2.9-boundary): returns core [Shop] because the favourites list feeds
  /// the shared `ShopCard` core widget, which is typed on the core DTO.
  Future<Either<Failure, List<Shop>>> getFavoriteShops();

  /// Synchronous boundary read for the shop-menu screen. Null → unknown id.
  ///
  /// TODO(P2.9-boundary): returns core [Shop] because the menu screen's product
  /// rows push the core `Product` across features (cart / product-details).
  Shop? shopById(String id);

  /// Synchronous boundary read for the shop-menu tab / rank structure.
  ///
  /// TODO(P2.9-boundary): returns core [JameiaCategory] — the menu graph is
  /// built from core `Product`s pushed across features.
  JameiaCategory? categoryById(String id);
}
