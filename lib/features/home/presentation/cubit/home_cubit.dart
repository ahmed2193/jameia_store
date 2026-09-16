import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart' show HomeBanner;
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/benefit_item_entity.dart';
import '../../domain/entities/featured_section_entity.dart';
import '../../domain/entities/gathering_card_entity.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_popup_entity.dart';
import '../../domain/entities/home_tile_entity.dart';
import '../../domain/entities/jameia_category_entity.dart';
import '../../domain/entities/keeta_address_entity.dart';
import '../../domain/entities/kingkong_item_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/entities/store_settings_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/select_home_filter_usecase.dart';

enum HomeStatus { initial, loading, loaded, error }

/// Home-feed state. Single immutable state driven by [HomeStatus]; the screen
/// reads `state.status` and the loaded fields. Carries every field the original
/// sealed `HomeLoaded` exposed, over the feature's framework-free entities.
///
/// BOUNDARY: [banners] stays the core `HomeBanner` DTO because the shared
/// `core/widgets/BannerCarousel` consumes that type. See `// TODO(P2.9-boundary)`.
class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.error,
    this.user,
    this.address,
    this.kingkong = const [],
    this.categories = const [],
    this.banners = const [],
    this.filters = const [],
    this.shops = const [],
    this.channels = const [],
    this.activeFilter = 0,
    this.bannerRail = const [],
    this.gatheringCards = const [],
    this.tiles = const [],
    this.benefits = const [],
    this.popups = const [],
    this.allSections = const [],
    this.sections = const [],
    this.promoProducts = const [],
    this.settings = const StoreSettingsEntity(),
    this.popupsShown = false,
  });

  final HomeStatus status;
  final String? error;

  final UserProfileEntity? user;
  final KeetaAddressEntity? address;
  final List<KingKongItemEntity> kingkong;

  /// Full category taxonomy (feeds the "Shop by category" carousel).
  final List<JameiaCategoryEntity> categories;

  // TODO(P2.9-boundary): core HomeBanner kept — shared BannerCarousel consumes it.
  final List<HomeBanner> banners;
  final List<String> filters;
  final List<ShopEntity> shops;
  final List<({String id, String name})> channels;
  final int activeFilter;

  // Reference home modules.
  final List<ShopEntity> bannerRail;
  final List<GatheringCardEntity> gatheringCards;
  final List<HomeTileEntity> tiles;
  final List<BenefitItemEntity> benefits;
  final List<HomePopupEntity> popups;

  // Jameia feed.
  /// ALL featured rails (immutable source).
  final List<FeaturedSectionEntity> allSections;

  /// The rails currently shown (filtered subset of [allSections]).
  final List<FeaturedSectionEntity> sections;
  final List<ProductEntity> promoProducts;

  /// Store settings the VIP / Mart hero card renders.
  final StoreSettingsEntity settings;

  /// Whether the home popup queue has already been shown this session. Lives in
  /// state (not a screen-local field) so the screen survives rebuilds/recreation
  /// without re-firing the queue.
  final bool popupsShown;

  HomeState copyWith({
    HomeStatus? status,
    String? error,
    UserProfileEntity? user,
    KeetaAddressEntity? address,
    List<KingKongItemEntity>? kingkong,
    List<JameiaCategoryEntity>? categories,
    List<HomeBanner>? banners,
    List<String>? filters,
    List<ShopEntity>? shops,
    List<({String id, String name})>? channels,
    int? activeFilter,
    List<ShopEntity>? bannerRail,
    List<GatheringCardEntity>? gatheringCards,
    List<HomeTileEntity>? tiles,
    List<BenefitItemEntity>? benefits,
    List<HomePopupEntity>? popups,
    List<FeaturedSectionEntity>? allSections,
    List<FeaturedSectionEntity>? sections,
    List<ProductEntity>? promoProducts,
    StoreSettingsEntity? settings,
    bool? popupsShown,
  }) =>
      HomeState(
        status: status ?? this.status,
        error: error ?? this.error,
        user: user ?? this.user,
        address: address ?? this.address,
        kingkong: kingkong ?? this.kingkong,
        categories: categories ?? this.categories,
        banners: banners ?? this.banners,
        filters: filters ?? this.filters,
        shops: shops ?? this.shops,
        channels: channels ?? this.channels,
        activeFilter: activeFilter ?? this.activeFilter,
        bannerRail: bannerRail ?? this.bannerRail,
        gatheringCards: gatheringCards ?? this.gatheringCards,
        tiles: tiles ?? this.tiles,
        benefits: benefits ?? this.benefits,
        popups: popups ?? this.popups,
        allSections: allSections ?? this.allSections,
        sections: sections ?? this.sections,
        promoProducts: promoProducts ?? this.promoProducts,
        settings: settings ?? this.settings,
        popupsShown: popupsShown ?? this.popupsShown,
      );

  @override
  List<Object?> get props =>
      [status, error, user, address, shops, activeFilter, banners, sections, popupsShown];
}

/// Page-scoped cubit — resolved via `sl<HomeCubit>()`; loads the feed on
/// construction directly through the [HomeRepository] (the pass-through
/// `GetHomeFeedUseCase` was collapsed). Filtering is delegated to
/// [SelectHomeFilterUseCase]; the once-per-session popup latch is a pure state
/// mutation.
class HomeCubit extends Cubit<HomeState> with SafeCubitMixin<HomeState> {
  HomeCubit(this._repository, this._selectHomeFilter)
      : super(const HomeState()) {
    load();
  }

  final HomeRepository _repository;
  final SelectHomeFilterUseCase _selectHomeFilter;

  /// The immutable feed snapshot (unfiltered source lists) — kept so filtering
  /// always works from the full lists, matching the original which re-read the
  /// full catalogue on every filter tap.
  HomeFeed? _feed;

  Future<void> load() async {
    // Preserve "popups already shown" across a reload (pull-to-refresh) so the
    // home popup queue stays once-per-session — matching the original widget-
    // state latch. A fresh first load keeps it false.
    final alreadyShown = state.status == HomeStatus.loaded && state.popupsShown;
    // Don't flash the skeleton on reload (pull-to-refresh): only the first load
    // shows the loading state, matching the original which emitted HomeLoaded
    // directly on reload.
    if (state.status != HomeStatus.loaded) {
      safeEmit(state.copyWith(status: HomeStatus.loading));
    }
    final result = await _repository.getHomeFeed();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: HomeStatus.error,
        error: failure.message,
      )),
      (feed) {
        _feed = feed;
        safeEmit(_stateFromFeed(feed, alreadyShown));
      },
    );
  }

  /// Build a fresh loaded state from [feed], resetting the active filter to the
  /// default and showing the full shops/sections — exactly as the original
  /// `load()` emitted a fresh `HomeLoaded` (activeFilter 0, full lists),
  /// preserving only the once-per-session popup latch.
  HomeState _stateFromFeed(HomeFeed feed, bool popupsShown) => HomeState(
        status: HomeStatus.loaded,
        user: feed.user,
        address: feed.address,
        kingkong: feed.kingkong,
        categories: feed.categories,
        banners: feed.banners,
        filters: feed.filters,
        shops: feed.shops,
        channels: feed.channels,
        activeFilter: 0,
        bannerRail: feed.bannerRail,
        gatheringCards: feed.gatheringCards,
        tiles: feed.tiles,
        benefits: feed.benefits,
        popups: feed.popups,
        allSections: feed.allSections,
        sections: feed.sections,
        promoProducts: feed.promoProducts,
        settings: feed.settings,
        popupsShown: popupsShown,
      );

  Future<void> selectFilter(int index) async {
    final feed = _feed;
    if (state.status != HomeStatus.loaded || feed == null) return;
    final result = await _selectHomeFilter(SelectHomeFilterParams(
      index: index,
      filters: feed.filters,
      shops: feed.shops,
      sections: feed.allSections,
      promoProducts: feed.promoProducts,
    ));
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: HomeStatus.error,
        error: failure.message,
      )),
      (r) => safeEmit(state.copyWith(
        activeFilter: index,
        shops: r.shops,
        sections: r.sections,
      )),
    );
  }

  /// Resolve the shop-screen navigation argument for a home featured product's
  /// SKU — routes the old inline `sl<KeetaRepository>().locationOfSku` read
  /// through the repository so the screen drops that direct dependency.
  String shopArgForProduct(String sku) => _repository.shopArgForProduct(sku);

  /// Mark the one-per-session home popup queue as shown. The screen reads
  /// [HomeState.popupsShown] before firing the queue, so this prevents a
  /// re-trigger across rebuilds. Pure state mutation — touches no data.
  void markPopupsShown() {
    if (state.status != HomeStatus.loaded || state.popupsShown) return;
    safeEmit(state.copyWith(popupsShown: true));
  }
}
