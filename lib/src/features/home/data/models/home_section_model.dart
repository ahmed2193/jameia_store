import '../../../../core/data/models/brand_model.dart';
import '../../../../core/data/models/category_model.dart';
import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/data/models/recipe_summary_model.dart';
import '../../../../core/error/exceptions.dart';
import 'home_icon_model.dart';

/// One block of `GET /v1/home` → `results.sections[]`. The wire is a union on
/// [type]; this DTO is its flat superset and the mapper picks the entity:
///
/// | [type] | reads |
/// |---|---|
/// | `rail` | [railSource] + the matching one of [products] / [categories] / [brands] / [recipes], [displayMode], [theme], [productGroupSlug] |
/// | `promo_cards` | [cards] |
/// | `promo_strip` | [badge], [configTitle], [subtitle], [linkType], [linkTarget], [theme], [endsAt] |
/// | `banner` | [imageUrl], [configTitle], [linkType], [linkTarget] |
///
/// Text arrives already resolved for `Accept-Language`.
class HomeSectionModel {
  const HomeSectionModel({
    required this.id,
    required this.type,
    this.sortOrder = 0,
    this.status = activeStatus,
    this.title = '',
    this.icon,
    this.iconColor = '',
    this.railSource = '',
    this.displayMode = '',
    this.theme = '',
    this.productGroupSlug = '',
    this.products = const <ProductModel>[],
    this.categories = const <CategoryModel>[],
    this.brands = const <BrandModel>[],
    this.recipes = const <RecipeSummaryModel>[],
    this.cards = const <HomePromoCardModel>[],
    this.badge = '',
    this.configTitle = '',
    this.subtitle = '',
    this.linkType = '',
    this.linkTarget = '',
    this.endsAt,
    this.imageUrl = '',
  });

  static const String idKey = 'id';
  static const String typeKey = 'type';
  static const String sortOrderKey = 'sortOrder';
  static const String statusKey = 'status';
  static const String titleKey = 'title';
  static const String iconKey = 'icon';
  static const String iconColorKey = 'iconColor';
  static const String configKey = 'config';
  static const String dataKey = 'data';
  static const String productGroupSlugKey = 'productGroupSlug';
  static const String sourceKey = 'source';
  static const String displayModeKey = 'displayMode';
  static const String themeKey = 'theme';
  static const String cardsKey = 'cards';
  static const String badgeKey = 'badge';
  static const String subtitleKey = 'subtitle';
  static const String linkTypeKey = 'linkType';
  static const String linkTargetKey = 'linkTarget';
  static const String endsAtKey = 'endsAt';
  static const String imageUrlKey = 'imageUrl';

  static const String activeStatus = 'active';
  static const String railType = 'rail';
  static const String promoCardsType = 'promo_cards';
  static const String promoStripType = 'promo_strip';
  static const String bannerType = 'banner';
  static const String productsSource = 'products';
  static const String categoriesSource = 'categories';
  static const String brandsSource = 'brands';
  static const String recipesSource = 'recipes';
  static const String _logName = 'HomeSectionModel';

  /// Throws [ParsingException] without an id or a type; the feed skips that
  /// section and keeps the rest.
  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('home section: id missing');
    final type = JsonRead.string(json[typeKey]);
    if (type == null) {
      throw const ParsingException('home section: type missing');
    }
    final config =
        JsonRead.object(json[configKey]) ?? const <String, dynamic>{};
    final source = JsonRead.string(config[sourceKey]) ?? '';
    final data = json[dataKey];
    return HomeSectionModel(
      id: id,
      type: type,
      sortOrder: JsonRead.integer(json[sortOrderKey]) ?? 0,
      status: JsonRead.string(json[statusKey]) ?? activeStatus,
      title: JsonRead.string(json[titleKey]) ?? '',
      icon: HomeIconModel.tryParse(json[iconKey]),
      iconColor: JsonRead.string(json[iconColorKey]) ?? '',
      railSource: source,
      displayMode: JsonRead.string(config[displayModeKey]) ?? '',
      theme: JsonRead.string(config[themeKey]) ?? '',
      productGroupSlug: JsonRead.string(json[productGroupSlugKey]) ?? '',
      products: source == productsSource
          ? JsonRead.rows(data, ProductModel.fromJson, logName: _logName)
          : const <ProductModel>[],
      categories: source == categoriesSource
          ? JsonRead.rows(data, CategoryModel.fromJson, logName: _logName)
          : const <CategoryModel>[],
      brands: source == brandsSource
          ? JsonRead.rows(data, BrandModel.fromJson, logName: _logName)
          : const <BrandModel>[],
      recipes: source == recipesSource
          ? JsonRead.rows(data, RecipeSummaryModel.fromJson, logName: _logName)
          : const <RecipeSummaryModel>[],
      cards: JsonRead.rows(
        config[cardsKey],
        HomePromoCardModel.fromJson,
        logName: _logName,
      ),
      badge: JsonRead.string(config[badgeKey]) ?? '',
      configTitle: JsonRead.string(config[titleKey]) ?? '',
      subtitle: JsonRead.string(config[subtitleKey]) ?? '',
      linkType: JsonRead.string(config[linkTypeKey]) ?? '',
      linkTarget: JsonRead.string(config[linkTargetKey]) ?? '',
      endsAt: JsonRead.dateTime(config[endsAtKey]),
      imageUrl: JsonRead.string(config[imageUrlKey]) ?? '',
    );
  }

  final String id;

  /// `rail` | `promo_cards` | `promo_strip` | `banner` (wire value).
  final String type;
  final int sortOrder;

  /// `active` | `inactive` (wire value).
  final String status;

  /// Section heading; `''` when the block has none.
  final String title;
  final HomeIconModel? icon;

  /// `emerald` | `amber` | `rose` | `violet` | `sky` | `orange` | `zinc` | `''`.
  final String iconColor;

  /// `products` | `categories` | `brands` | `recipes` (rail only).
  final String railSource;

  /// `slider` | `grid` (rail only).
  final String displayMode;

  /// Rail: `default` | `sale` | `deals` | `featured`.
  /// Promo strip: `store` | `sale` | `deals`.
  final String theme;

  /// Collection slug behind a product rail → its "view all" target.
  final String productGroupSlug;
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final List<BrandModel> brands;
  final List<RecipeSummaryModel> recipes;
  final List<HomePromoCardModel> cards;
  final String badge;

  /// `config.title` of a promo strip / banner (distinct from the heading).
  final String configTitle;
  final String subtitle;

  /// `collection` | `category` | `brand` | `url` | `recipes` | `''`.
  final String linkType;
  final String linkTarget;

  /// Promo strip countdown end, or `null`.
  final DateTime? endsAt;

  /// Banner artwork.
  final String imageUrl;
}

/// One card of a `promo_cards` section (`config.cards[]`).
class HomePromoCardModel {
  const HomePromoCardModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.icon,
    this.linkType = '',
    this.linkTarget = '',
    this.color = '',
  });

  static const String idKey = 'id';
  static const String titleKey = 'title';
  static const String subtitleKey = 'subtitle';
  static const String iconKey = 'icon';
  static const String linkTypeKey = 'linkType';
  static const String linkTargetKey = 'linkTarget';
  static const String colorKey = 'color';

  /// Throws [ParsingException] without an id or a title.
  factory HomePromoCardModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('promo card: id missing');
    final title = JsonRead.string(json[titleKey]);
    if (title == null) {
      throw const ParsingException('promo card: title missing');
    }
    return HomePromoCardModel(
      id: id,
      title: title,
      subtitle: JsonRead.string(json[subtitleKey]) ?? '',
      icon: HomeIconModel.tryParse(json[iconKey]),
      linkType: JsonRead.string(json[linkTypeKey]) ?? '',
      linkTarget: JsonRead.string(json[linkTargetKey]) ?? '',
      color: JsonRead.string(json[colorKey]) ?? '',
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final HomeIconModel? icon;
  final String linkType;
  final String linkTarget;

  /// A web gradient class pair (`from-violet-600 to-purple-700`); the mapper
  /// reads the first colour family out of it.
  final String color;
}
