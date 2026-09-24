import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../domain/entities/home_announcement_item.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_icon.dart';
import '../../domain/entities/home_link.dart';
import '../../domain/entities/home_section_entity.dart';
import '../../domain/entities/home_slide_entity.dart';
import '../models/home_announcement_model.dart';
import '../models/home_feed_model.dart';
import '../models/home_icon_model.dart';
import '../models/home_section_model.dart';
import '../models/home_slide_model.dart';

/// [HomeFeedModel] (wire) → [HomeFeed]: only what is live and has content, in
/// backend order.
extension HomeFeedMapper on HomeFeedModel {
  HomeFeed toEntity() {
    final liveSlides =
        slides
            .where((slide) => slide.status == HomeSlideModel.activeStatus)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final liveSections =
        sections
            .where((section) => section.status == HomeSectionModel.activeStatus)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return HomeFeed(
      announcements: announcement.enabled
          ? [for (final item in announcement.items) item.toEntity()]
          : const <HomeAnnouncementItem>[],
      slides: [for (final slide in liveSlides) slide.toEntity()],
      sections: [for (final section in liveSections) ?section.toEntity()],
      categories: categories.toTree(),
    );
  }
}

extension HomeSlideMapper on HomeSlideModel {
  HomeSlideEntity toEntity() => HomeSlideEntity(
    id: id,
    imageUrl: imageUrl,
    title: title,
    description: description,
  );
}

extension HomeAnnouncementItemMapper on HomeAnnouncementItemModel {
  HomeAnnouncementItem toEntity() =>
      HomeAnnouncementItem(id: id, text: text, icon: icon.toEntity());
}

extension HomeIconMapper on HomeIconModel? {
  static const String _customSource = 'custom';

  HomeIcon toEntity() {
    final model = this;
    if (model == null) return const HomeIcon();
    if (model.source == _customSource) return HomeIcon(imageUrl: model.url);
    return HomeIcon(key: HomeWire.iconKey(model.key));
  }
}

extension HomeSectionMapper on HomeSectionModel {
  /// `null` for a block with nothing to show (an empty rail, a banner without
  /// an image) or of a type this build does not know.
  HomeSectionEntity? toEntity() {
    final sectionIcon = icon.toEntity();
    final sectionAccent = HomeWire.accent(iconColor);
    switch (type) {
      case HomeSectionModel.railType:
        return _rail(sectionIcon, sectionAccent);
      case HomeSectionModel.promoCardsType:
        if (cards.isEmpty) return null;
        return HomePromoCardsSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          cards: [for (final card in cards) card.toEntity()],
        );
      case HomeSectionModel.promoStripType:
        if (configTitle.isEmpty) return null;
        return HomePromoStripSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          headline: configTitle,
          badge: badge,
          subtitle: subtitle,
          link: HomeWire.link(linkType, linkTarget),
          theme: HomeWire.theme(theme, fallback: HomeSectionTheme.store),
          endsAt: endsAt,
        );
      case HomeSectionModel.bannerType:
        if (imageUrl.isEmpty) return null;
        return HomeBannerSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          imageUrl: imageUrl,
          caption: configTitle,
          link: HomeWire.link(linkType, linkTarget),
        );
      default:
        return null;
    }
  }

  HomeSectionEntity? _rail(HomeIcon sectionIcon, HomeAccent sectionAccent) {
    switch (railSource) {
      case HomeSectionModel.productsSource:
        if (products.isEmpty) return null;
        return HomeProductRailSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          products: products.toEntities(),
          theme: HomeWire.theme(theme, fallback: HomeSectionTheme.standard),
          layout: displayMode == HomeWire.gridLayout
              ? HomeRailLayout.grid
              : HomeRailLayout.slider,
          collectionSlug: productGroupSlug,
        );
      case HomeSectionModel.categoriesSource:
        if (categories.isEmpty) return null;
        return HomeCategoryRailSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          categories: categories.toEntities(),
        );
      case HomeSectionModel.brandsSource:
        if (brands.isEmpty) return null;
        return HomeBrandRailSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          brands: brands.toEntities(),
        );
      case HomeSectionModel.recipesSource:
        if (recipes.isEmpty) return null;
        return HomeRecipeRailSection(
          id: id,
          title: title,
          icon: sectionIcon,
          accent: sectionAccent,
          recipes: recipes.toEntities(),
        );
      default:
        return null;
    }
  }
}

extension HomePromoCardMapper on HomePromoCardModel {
  HomePromoCard toEntity() => HomePromoCard(
    id: id,
    title: title,
    subtitle: subtitle,
    icon: icon.toEntity(),
    link: HomeWire.link(linkType, linkTarget),
    accent: HomeWire.accentOfGradient(color),
  );
}

/// Wire value → enum tables of the home payloads. An unknown value maps to the
/// neutral case, never throws: the backend adds icons / colours / link kinds
/// without an app release.
abstract final class HomeWire {
  static const String gridLayout = 'grid';

  static HomeLink link(String type, String target) => HomeLink(
    type: switch (type) {
      'collection' => HomeLinkType.collection,
      'category' => HomeLinkType.category,
      'brand' => HomeLinkType.brand,
      'recipes' => HomeLinkType.recipes,
      'url' => HomeLinkType.url,
      _ => HomeLinkType.none,
    },
    target: target,
  );

  static HomeSectionTheme theme(
    String wire, {
    required HomeSectionTheme fallback,
  }) => switch (wire) {
    'default' => HomeSectionTheme.standard,
    'sale' => HomeSectionTheme.sale,
    'deals' => HomeSectionTheme.deals,
    'featured' => HomeSectionTheme.featured,
    'store' => HomeSectionTheme.store,
    _ => fallback,
  };

  static HomeAccent accent(String wire) => switch (wire) {
    'emerald' => HomeAccent.emerald,
    'amber' => HomeAccent.amber,
    'rose' => HomeAccent.rose,
    'violet' => HomeAccent.violet,
    'sky' => HomeAccent.sky,
    'orange' => HomeAccent.orange,
    'zinc' => HomeAccent.zinc,
    _ => HomeAccent.none,
  };

  /// A promo card's colour is a web gradient class pair
  /// (`from-violet-600 to-purple-700`): the first family the app knows wins.
  static HomeAccent accentOfGradient(String gradient) {
    const families = <String, HomeAccent>{
      'emerald': HomeAccent.emerald,
      'green': HomeAccent.emerald,
      'teal': HomeAccent.emerald,
      'amber': HomeAccent.amber,
      'yellow': HomeAccent.amber,
      'rose': HomeAccent.rose,
      'red': HomeAccent.rose,
      'pink': HomeAccent.rose,
      'violet': HomeAccent.violet,
      'purple': HomeAccent.violet,
      'indigo': HomeAccent.violet,
      'sky': HomeAccent.sky,
      'blue': HomeAccent.sky,
      'cyan': HomeAccent.sky,
      'orange': HomeAccent.orange,
      'zinc': HomeAccent.zinc,
      'slate': HomeAccent.zinc,
      'gray': HomeAccent.zinc,
    };
    for (final word in gradient.split(RegExp('[ -]'))) {
      final accent = families[word];
      if (accent != null) return accent;
    }
    return HomeAccent.none;
  }

  static HomeIconKey iconKey(String wire) => switch (wire) {
    'truck' => HomeIconKey.truck,
    'tag' => HomeIconKey.tag,
    'zap' => HomeIconKey.zap,
    'gift' => HomeIconKey.gift,
    'percent' => HomeIconKey.percent,
    'shopping_bag' => HomeIconKey.shoppingBag,
    'shopping_cart' => HomeIconKey.shoppingCart,
    'store' => HomeIconKey.store,
    'clock' => HomeIconKey.clock,
    'calendar' => HomeIconKey.calendar,
    'star' => HomeIconKey.star,
    'heart' => HomeIconKey.heart,
    'check_circle' => HomeIconKey.checkCircle,
    'info' => HomeIconKey.info,
    'phone' => HomeIconKey.phone,
    'mail' => HomeIconKey.mail,
    'message' => HomeIconKey.message,
    'map_pin' => HomeIconKey.mapPin,
    'home' => HomeIconKey.home,
    'leaf' => HomeIconKey.leaf,
    'utensils' => HomeIconKey.utensils,
    'chef_hat' => HomeIconKey.chefHat,
    'coffee' => HomeIconKey.coffee,
    'sparkles' => HomeIconKey.sparkles,
    'flame' => HomeIconKey.flame,
    'award' => HomeIconKey.award,
    'trending_up' => HomeIconKey.trendingUp,
    'megaphone' => HomeIconKey.megaphone,
    _ => HomeIconKey.other,
  };
}
