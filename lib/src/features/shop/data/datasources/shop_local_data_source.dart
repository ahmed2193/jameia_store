import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the shop feature. The live Jameia pages hit
/// `/api/shop/detail` + a favourites endpoint; here both resolve straight off
/// the in-memory [JameiaRepository] (the single offline data backend).
///
/// These are the raw catalogue reads the shop-detail / favourites cubits used to
/// do inline against the repository. The datasource stays in core DTOs
/// ([Shop] / [JameiaCategory]); the repository maps to framework-free entities
/// (or keeps the DTO at a cross-feature/core-widget boundary — see the repo).
abstract class ShopLocalDataSource {
  /// The [Shop] behind the shop-detail panel. Throws when the id is unknown so
  /// the repository surfaces a failure state instead of a wrong shop.
  Shop shopDetail(String shopId);

  /// Shops shown on the favourites feed. Dummy data only — the whole catalogue
  /// stands in for "favourites" until a real backend exists.
  List<Shop> favoriteShops();

  /// Nullable lookup for the shop-menu screen boundary (the menu pushes core
  /// [Product]s across features, so it stays in core DTOs). Null → unknown id.
  Shop? shopById(String id);

  /// The jameia category behind a shop-menu screen (tab / rank structure).
  /// Null → no matching category (the screen falls back to a single tab).
  JameiaCategory? categoryById(String id);
}

class ShopLocalDataSourceImpl implements ShopLocalDataSource {
  ShopLocalDataSourceImpl(this.catalog);

  final JameiaRepository catalog;

  @override
  Shop shopDetail(String shopId) {
    final shop = catalog.shopById(shopId);
    if (shop == null) throw StateError('Shop not found: $shopId');
    return shop;
  }

  @override
  List<Shop> favoriteShops() => catalog.shops;

  @override
  Shop? shopById(String id) => catalog.shopById(id);

  @override
  JameiaCategory? categoryById(String id) => catalog.categoryById(id);
}
