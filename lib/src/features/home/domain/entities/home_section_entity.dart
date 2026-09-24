import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/recipe_summary_entity.dart';
import 'home_icon.dart';
import 'home_link.dart';

/// Visual theme of a product rail / promo strip.
enum HomeSectionTheme { standard, sale, deals, featured, store }

/// How a rail lays its items out.
enum HomeRailLayout { slider, grid }

/// One block of the home screen, in backend order. The backend composes the
/// screen from these (`GET /v1/home` → `sections[]`); the page switches on the
/// subtype and never invents a block of its own.
sealed class HomeSectionEntity extends Equatable {
  const HomeSectionEntity({
    required this.id,
    this.title = '',
    this.icon = const HomeIcon(),
    this.accent = HomeAccent.none,
  });

  final String id;

  /// Heading; `''` = the block has none. Already resolved for the language.
  final String title;
  final HomeIcon icon;
  final HomeAccent accent;

  bool get hasTitle => title.isNotEmpty;
}

/// A rail of products — usually backed by a collection ([collectionSlug]),
/// which is where "view all" leads.
class HomeProductRailSection extends HomeSectionEntity {
  const HomeProductRailSection({
    required super.id,
    required this.products,
    super.title,
    super.icon,
    super.accent,
    this.theme = HomeSectionTheme.standard,
    this.layout = HomeRailLayout.slider,
    this.collectionSlug = '',
  });

  final List<CatalogProductEntity> products;
  final HomeSectionTheme theme;
  final HomeRailLayout layout;
  final String collectionSlug;

  bool get hasViewAll => collectionSlug.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    title,
    icon,
    accent,
    products,
    theme,
    layout,
    collectionSlug,
  ];
}

class HomeCategoryRailSection extends HomeSectionEntity {
  const HomeCategoryRailSection({
    required super.id,
    required this.categories,
    super.title,
    super.icon,
    super.accent,
  });

  final List<CatalogCategoryEntity> categories;

  @override
  List<Object?> get props => [id, title, icon, accent, categories];
}

class HomeBrandRailSection extends HomeSectionEntity {
  const HomeBrandRailSection({
    required super.id,
    required this.brands,
    super.title,
    super.icon,
    super.accent,
  });

  final List<BrandEntity> brands;

  @override
  List<Object?> get props => [id, title, icon, accent, brands];
}

class HomeRecipeRailSection extends HomeSectionEntity {
  const HomeRecipeRailSection({
    required super.id,
    required this.recipes,
    super.title,
    super.icon,
    super.accent,
  });

  final List<RecipeSummaryEntity> recipes;

  @override
  List<Object?> get props => [id, title, icon, accent, recipes];
}

/// "Shop by occasion": a row of coloured cards, each a link.
class HomePromoCardsSection extends HomeSectionEntity {
  const HomePromoCardsSection({
    required super.id,
    required this.cards,
    super.title,
    super.icon,
    super.accent,
  });

  final List<HomePromoCard> cards;

  @override
  List<Object?> get props => [id, title, icon, accent, cards];
}

class HomePromoCard extends Equatable {
  const HomePromoCard({
    required this.id,
    required this.title,
    required this.link,
    this.subtitle = '',
    this.icon = const HomeIcon(),
    this.accent = HomeAccent.none,
  });

  final String id;
  final String title;
  final String subtitle;
  final HomeIcon icon;
  final HomeLink link;
  final HomeAccent accent;

  @override
  List<Object?> get props => [id, title, subtitle, icon, link, accent];
}

/// A full-width call-out ("Flash deals — up to 30% off"), optionally counting
/// down to [endsAt].
class HomePromoStripSection extends HomeSectionEntity {
  const HomePromoStripSection({
    required super.id,
    required this.headline,
    required this.link,
    super.title,
    super.icon,
    super.accent,
    this.badge = '',
    this.subtitle = '',
    this.theme = HomeSectionTheme.store,
    this.endsAt,
  });

  final String headline;
  final String badge;
  final String subtitle;
  final HomeLink link;
  final HomeSectionTheme theme;
  final DateTime? endsAt;

  /// An expired strip leaves the screen.
  bool isLiveAt(DateTime now) => endsAt == null || endsAt!.isAfter(now);

  @override
  List<Object?> get props => [
    id,
    title,
    icon,
    accent,
    headline,
    badge,
    subtitle,
    link,
    theme,
    endsAt,
  ];
}

/// A promo strip and the product rail it advertises, as ONE block.
///
/// The backend joins the two itself — the strip links to a collection and
/// the rail is that collection ([HomePromoStripSection.link] target ==
/// [HomeProductRailSection.collectionSlug]) — so this is a real relation,
/// never a guess from the order sections happen to arrive in.
class HomeThemedBlockSection extends HomeSectionEntity {
  HomeThemedBlockSection({required this.strip, required this.rail})
    : super(
        id: strip.id,
        title: rail.title,
        icon: rail.icon,
        accent: rail.accent,
      );

  final HomePromoStripSection strip;
  final HomeProductRailSection rail;

  /// The rail decides the colour of the block; the strip fills in when the
  /// rail itself carries no theme.
  HomeSectionTheme get theme =>
      rail.theme != HomeSectionTheme.standard ? rail.theme : strip.theme;

  @override
  List<Object?> get props => [id, title, icon, accent, strip, rail];
}

/// One image banner.
class HomeBannerSection extends HomeSectionEntity {
  const HomeBannerSection({
    required super.id,
    required this.imageUrl,
    required this.link,
    super.title,
    super.icon,
    super.accent,
    this.caption = '',
  });

  final String imageUrl;
  final String caption;
  final HomeLink link;

  @override
  List<Object?> get props => [id, title, icon, accent, imageUrl, caption, link];
}
