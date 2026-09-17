import 'package:equatable/equatable.dart';

import '../../../../core/data/models/models.dart' show HomeBanner;
import 'benefit_item_entity.dart';
import 'featured_section_entity.dart';
import 'gathering_card_entity.dart';
import 'home_popup_entity.dart';
import 'home_tile_entity.dart';
import 'jameia_category_entity.dart';
import 'jameia_address_entity.dart';
import 'kingkong_item_entity.dart';
import 'product_entity.dart';
import 'shop_entity.dart';
import 'store_settings_entity.dart';
import 'user_profile_entity.dart';

/// Immutable snapshot of the whole home feed — the domain result produced by the
/// home repository. It carries every source list the home tab renders, over the
/// feature's framework-free entities so presentation never reaches into the
/// catalogue directly.
///
/// BOUNDARY: [banners] stays the core `HomeBanner` DTO because it is rendered by
/// the shared `core/widgets/BannerCarousel`, which consumes that DTO type
/// directly. See `// TODO(P2.9-boundary)`.
class HomeFeed extends Equatable {
  const HomeFeed({
    required this.user,
    required this.address,
    required this.kingkong,
    this.categories = const [],
    required this.banners,
    required this.filters,
    required this.shops,
    this.channels = const [],
    this.bannerRail = const [],
    this.gatheringCards = const [],
    this.tiles = const [],
    this.benefits = const [],
    this.popups = const [],
    this.allSections = const [],
    this.sections = const [],
    this.promoProducts = const [],
    this.settings = const StoreSettingsEntity(),
  });

  final UserProfileEntity user;
  final JameiaAddressEntity address;
  final List<KingKongItemEntity> kingkong;

  /// Full category taxonomy (feeds the "Shop by category" carousel).
  final List<JameiaCategoryEntity> categories;

  // TODO(P2.9-boundary): core HomeBanner kept — shared BannerCarousel consumes it.
  final List<HomeBanner> banners;
  final List<String> filters;
  final List<ShopEntity> shops;
  final List<({String id, String name})> channels;

  // Reference home modules.
  final List<ShopEntity> bannerRail;
  final List<GatheringCardEntity> gatheringCards;
  final List<HomeTileEntity> tiles;
  final List<BenefitItemEntity> benefits;
  final List<HomePopupEntity> popups;

  // Jameia feed.
  /// ALL featured rails (immutable source).
  final List<FeaturedSectionEntity> allSections;

  /// The rails shown on first load (equal to [allSections] until a filter is
  /// applied).
  final List<FeaturedSectionEntity> sections;
  final List<ProductEntity> promoProducts;

  /// Store settings the VIP / Mart hero card renders (prep time + hero cards).
  final StoreSettingsEntity settings;

  @override
  List<Object?> get props => [
    user,
    address,
    kingkong,
    categories,
    banners,
    filters,
    shops,
    channels,
    bannerRail,
    gatheringCards,
    tiles,
    benefits,
    popups,
    allSections,
    sections,
    promoProducts,
    settings,
  ];
}
