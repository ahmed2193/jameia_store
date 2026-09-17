import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the home tab. The live Jameia surface stitches together
/// several endpoints (`home_page_main` / `osg_home`); here every list comes from
/// the in-memory [JameiaRepository] catalogue. Each method wraps a read the
/// `HomeCubit` used to do inline.
abstract class HomeLocalDataSource {
  UserProfile user();
  JameiaAddress defaultAddress();
  List<KingKongItem> kingkong();
  List<JameiaCategory> categories();
  List<HomeBanner> banners();
  List<String> filters();
  List<Shop> shops();

  /// Featured-section names exposed as home channel pills (first 12).
  List<({String id, String name})> channels();
  List<Shop> bannerRail();
  List<GatheringCard> gatheringCards();
  List<HomeTile> tiles();
  List<BenefitItem> benefits();
  List<HomePopup> popups();
  List<FeaturedSection> sections();
  List<Product> promoProducts();

  /// Store settings the VIP / Mart hero card renders (prep time + hero cards).
  JameiaSettings settings();

  /// Where a product SKU lives in the taxonomy — used to deep-link a home
  /// featured product to its real shop tab + rank (`null` when not found).
  ProductLocation? locationOfSku(String sku);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl(this.catalog);

  final JameiaRepository catalog;

  @override
  UserProfile user() => catalog.user;

  @override
  JameiaAddress defaultAddress() => catalog.defaultAddress;

  @override
  List<KingKongItem> kingkong() => catalog.kingkong;

  @override
  List<JameiaCategory> categories() => catalog.categories;

  @override
  List<HomeBanner> banners() => catalog.banners;

  @override
  List<String> filters() => catalog.filters;

  @override
  List<Shop> shops() => catalog.shops;

  @override
  List<({String id, String name})> channels() =>
      catalog.features.take(12).toList();

  @override
  List<Shop> bannerRail() => catalog.bannerRail;

  @override
  List<GatheringCard> gatheringCards() => catalog.gatheringCards;

  @override
  List<HomeTile> tiles() => catalog.homeTiles;

  @override
  List<BenefitItem> benefits() => catalog.benefits;

  @override
  List<HomePopup> popups() => catalog.homePopups;

  @override
  List<FeaturedSection> sections() => catalog.sections;

  @override
  List<Product> promoProducts() => catalog.promoProducts;

  @override
  JameiaSettings settings() => catalog.settings;

  @override
  ProductLocation? locationOfSku(String sku) => catalog.locationOfSku(sku);
}
