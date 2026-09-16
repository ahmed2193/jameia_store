import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the discovery channel surfaces (channel list, KingKong
/// landing, self-pickup, meal-for-one, fixed-price). The live KeeTa app hits
/// `v2/homePage/*` feeds; here every read resolves synchronously off the
/// in-memory [KeetaRepository].
///
/// These are RAW catalogue reads only — the scene/sub-category derivation,
/// distance sorting, curation bucketing and flash-host selection live in the
/// discovery use cases (see `domain/usecases`), not here.
abstract class DiscoveryLocalDataSource {
  /// Full shop feed (channel list + meal-for-one seed, pickup source).
  List<Shop> allShops();

  /// Filter-chip labels (`filterId` / `filterDisplayName`).
  List<String> filters();

  /// Restaurant-only pool (KingKong food / meal categories).
  List<Shop> restaurants();

  /// Grocery-only pool (KingKong grocery / pharmacy / flowers categories).
  List<Shop> groceries();

  /// A shop by id (flash-price host lookup); falls back to the first shop.
  Shop shopById(String id);
}

class DiscoveryLocalDataSourceImpl implements DiscoveryLocalDataSource {
  DiscoveryLocalDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  @override
  List<Shop> allShops() => catalog.shops;

  @override
  List<String> filters() => catalog.filters;

  @override
  List<Shop> restaurants() => catalog.restaurants;

  @override
  List<Shop> groceries() => catalog.groceries;

  @override
  Shop shopById(String id) {
    final shop = catalog.shopById(id);
    if (shop == null) throw StateError('Shop not found: $id');
    return shop;
  }
}
