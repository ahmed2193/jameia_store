import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../../notifications/presentation/cubit/unread_notifications_state.dart';
import '../../../store_mode/presentation/cubit/store_mode_cubit.dart';
// TODO(P2.9-boundary): data-layer reverse mapper imported into presentation to
// rebuild the core Product for product_details' ProductDetailPage (DTO consumer).
import '../../data/mappers/product_mapper.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/home_cubit.dart';
import '../popups/home_popup_host.dart';
import '../util/shop_display.dart';
import '../widgets/bottom_overlay_bar.dart';
import '../widgets/featured_section_rail.dart';
import '../widgets/gathering_carousel.dart';
import '../widgets/jameia_categories_rail.dart';
import '../widgets/jameia_home_header.dart';
import '../widgets/shop_banner_rail.dart';
import '../widgets/sticky_benefits_bar.dart';
import '../widgets/vip_mart_card.dart';

/// Jameia Home tab — reference section order (`home_page_main` / `osg_home`):
/// operation header → kingkong → shop-banner rail → gathering carousel → tiles
/// → promo banner → channels → sticky benefits → filter chips → feed
/// (golden/grocery/theme cards) → bottom floating overlay + popup queue.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _overlayDismissed = false;
  final ScrollController _scrollController = ScrollController();
  // Key on the pinned filter-tabs sliver so a tab tap can scroll it to pin
  // right under the collapsed header (list then starts cleanly under the tabs).
  final GlobalKey _tabsSliverKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openShop(BuildContext context, String shopId) =>
      context.push(Routes.shop, extra: shopId);

  /// Flip the store mode (VIP ⇄ Mart). The active cart is priced for one mode,
  /// so switching clears it (matches Jameia/jm3eia store-switch behavior).
  void _setVip(BuildContext context, bool vip) {
    final store = context.read<StoreModeCubit>();
    if (store.state.isVip == vip) return;
    store.setVip(vip);
    context.read<CartCubit>().clear();
  }

  /// Open a featured product's REAL shop — resolve its category → sub → rank and
  /// deep-link the shop screen to that tab + rank (arg form `catId~subId~rankId`).
  /// Falls back to the first category when the product isn't in the taxonomy.
  void _openProductShop(BuildContext context, ProductEntity p) {
    // B2: the taxonomy lookup that used to read sl<JameiaRepository>() directly
    // now routes through the cubit → home repository.
    final arg = context.read<HomeCubit>().shopArgForProduct(p.sku);
    context.push(Routes.shop, extra: arg);
  }

  /// Open a product's full-screen detail page (the KeeMart PDP).
  void _openProductDetail(BuildContext context, ProductEntity p) {
    // TODO(P2.9-boundary): rebuild core Product for product_details' PDP screen.
    context.push(Routes.productDetail, extra: p.toModel());
  }

  /// Open the address flow (saved-address list / select), then refresh Home so
  /// the address bar reflects any newly chosen default.
  Future<void> _openAddress(BuildContext context) async {
    await context.push(Routes.addressList);
    if (context.mounted) context.read<HomeCubit>().load();
  }

  /// Select a filter AND scroll the app bar up so the pinned tabs dock right
  /// under the collapsed header with the tab's list starting under them. Runs on
  /// EVERY tap (even re-tapping the active tab), post-frame so the freshly
  /// filtered list is laid out before we compute the target.
  void _onSelectFilter(int i) {
    context.read<HomeCubit>().selectFilter(i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToTabs();
    });
  }

  /// Scroll so the pinned filter tabs sit flush under the collapsed header.
  ///
  /// Deterministic: the target offset is the tabs sliver's `precedingScrollExtent`
  /// (everything above it: expanded header + promo/categories/rails/banners)
  /// minus the collapsed header extent (status-bar inset + 52dp chrome). At that
  /// offset the header is fully collapsed, the tabs pin right beneath it, and the
  /// section list begins directly under the tabs.
  void _scrollToTabs() {
    if (!_scrollController.hasClients) return;
    final ro = _tabsSliverKey.currentContext?.findRenderObject();
    if (ro is! RenderSliver) return;
    final collapsedHeader = MediaQuery.paddingOf(context).top + 52.0;
    final target = (ro.constraints.precedingScrollExtent - collapsedHeader)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: MotionGuard.duration(context, AppMotion.page),
      curve: AppMotion.signature,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<HomeCubit, HomeState>(
        // Skip whole-feed rebuilds for generic state ticks (e.g.
        // markPopupsShown); only rebuild on a type change or a real feed change.
        // The scroll-to-tabs on a filter tap is driven by [_onSelectFilter], not
        // by a state listener, so it fires on every tap (even the active one).
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            (prev.status == HomeStatus.loaded &&
                curr.status == HomeStatus.loaded &&
                (prev.activeFilter != curr.activeFilter ||
                    prev.sections != curr.sections ||
                    prev.shops != curr.shops)),
        builder: (context, state) {
          switch (state.status) {
            case HomeStatus.loaded:
              return _loaded(context, state);
            case HomeStatus.error:
              return ErrorView(onRetry: () => context.read<HomeCubit>().load());
            case HomeStatus.initial:
            case HomeStatus.loading:
              return const Skeletonized(loading: true, child: HomeSkeleton());
          }
        },
      ),
    );
  }

  Widget _loaded(BuildContext context, HomeState s) {
    final railShop = s.bannerRail.isNotEmpty ? s.bannerRail.first : null;
    final showOverlay = !_overlayDismissed && railShop != null;

    return VisibilityDetector(
      key: const Key('home-tab-visibility'),
      onVisibilityChanged: (info) {
        // Fire the popup queue only once Home is actually the visible tab — the
        // shell's IndexedStack builds every tab up-front, so a plain post-frame
        // trigger would otherwise fire while another tab is on screen.
        // The shown-flag lives in cubit state; read it live (this subtree may
        // not rebuild on the markPopupsShown tick).
        if (!mounted || s.popups.isEmpty) return;
        final cubit = context.read<HomeCubit>();
        final current = cubit.state;
        if (current.status != HomeStatus.loaded || current.popupsShown) return;
        if (info.visibleFraction > 0.5) {
          cubit.markPopupsShown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showHomePopups(context, s.popups);
          });
        }
      },
      child: Stack(
        children: [
          // Clamp the single-column feed so it doesn't stretch edge-to-edge on
          // tablets/wide screens; on phones it's a no-op (width < 720dp).
          ContentClamp(
            child: BrandedRefresh(
              onRefresh: () async => context.read<HomeCubit>().load(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Jameia orange banner hero (address pill + floating search) —
                  // pinned, collapses to a compact bar on scroll-up.
                  // The bell's unread dot follows the app-global badge cubit;
                  // only this sliver rebuilds when it flips.
                  BlocSelector<
                    UnreadNotificationsCubit,
                    UnreadNotificationsState,
                    bool
                  >(
                    selector: (unread) => unread.hasUnread,
                    builder: (context, hasUnread) => jameiaHomeHeaderSliver(
                      address: s.address!,
                      topPad: MediaQuery.paddingOf(context).top,
                      screenWidth: MediaQuery.sizeOf(context).width,
                      onAddressTap: () => _openAddress(context),
                      onSearch: () => context.push(Routes.search),
                      onNotifications: () => context.push(Routes.notifications),
                      hasUnreadNotifications: hasUnread,
                    ),
                  ),
                  // Hero seam → cards gap (jm3eia leaves ~16dp clearance).
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // VIP / Fast-delivery promo cards sit above categories (jm3eia order).
                  SliverToBoxAdapter(
                    child: VipMartCard(
                      settings: s.settings,
                      onToggle: (vip) => _setVip(context, vip),
                    ),
                  ),
                  // "Shop by category" image-card carousel.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: JameiaCategoriesRail(
                        categories: s.categories,
                        onOpenCategory: (id) => _openShop(context, id),
                        onViewAll: () {
                          if (s.categories.isNotEmpty) {
                            _openShop(context, s.categories.first.id);
                          }
                        },
                      ),
                    ),
                  ),
                  if (s.bannerRail.isNotEmpty)
                    SliverToBoxAdapter(
                      child: ShopBannerRail(
                        title: 'home.featured_for_you'.tr(),
                        shops: s.bannerRail,
                        onOpenShop: (id) => _openShop(context, id),
                      ),
                    ),
                  if (s.gatheringCards.isNotEmpty)
                    SliverToBoxAdapter(
                      child: GatheringCarousel(
                        title: 'home.deals_you_love'.tr(),
                        cards: s.gatheringCards,
                        onOpen: (scheme) => _openShop(context, scheme),
                      ),
                    ),
                  SliverToBoxAdapter(child: BannerCarousel(banners: s.banners)),
                  SliverToBoxAdapter(
                    child: _ChannelsStrip(channels: s.channels),
                  ),
                  if (s.benefits.isNotEmpty)
                    SliverToBoxAdapter(
                      child: StickyBenefitsBar(benefits: s.benefits),
                    ),
                  // Pinned sort/filter tabs — sticks just under the header on scroll.
                  SliverPersistentHeader(
                    key: _tabsSliverKey,
                    pinned: true,
                    delegate: _FilterTabsDelegate(
                      filters: s.filters,
                      active: s.activeFilter,
                      onSelect: _onSelectFilter,
                    ),
                  ),
                  // Featured-section rails: one horizontal product rail per section.
                  // The rail product cards are fed by the Jameia catalogue and add to
                  // the cart at the VIP-correct unit price.
                  SliverList.builder(
                    itemCount: s.sections.length,
                    itemBuilder: (_, i) {
                      final section = s.sections[i];
                      return StaggerEntrance(
                        index: i,
                        child: FeaturedSectionRail(
                          section: section,
                          onOpenProduct: (p) => _openProductDetail(context, p),
                          onViewAll: () {
                            if (section.products.isNotEmpty) {
                              _openProductShop(context, section.products.first);
                            }
                          },
                        ),
                      );
                    },
                  ),

                  // Trailing space. Short filtered lists get a full extra screen so
                  // the view can still scroll up far enough to pin the filter tabs
                  // (i.e. the filtered list starts cleanly right under them).
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: s.sections.length < 5
                          ? MediaQuery.sizeOf(context).height
                          : AppSpacing.s24 + 56,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showOverlay)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: BottomOverlayBar(
                    text:
                        '${railShop.displayName} · ${railShop.promo.isNotEmpty ? railShop.promo : 'home.order_now'.tr()}',
                    image: railShop.logo,
                    onTap: () => _openShop(context, railShop.id),
                    onClose: () => setState(() => _overlayDismissed = true),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Pinned sort/filter tabs (28dp pills) — sticks under the header on scroll ──
class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  _FilterTabsDelegate({
    required this.filters,
    required this.active,
    required this.onSelect,
  });
  final List<String> filters;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  double get minExtent => 52; // 28dp pill + 12dp top/bottom padding
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _FilterTabsBar(filters: filters, active: active, onSelect: onSelect);
  }

  @override
  bool shouldRebuild(covariant _FilterTabsDelegate old) =>
      old.active != active || old.filters != filters;
}

/// Horizontal filter-tab strip that auto-scrolls the tapped/active tab to the
/// centre of the viewport.
class _FilterTabsBar extends StatefulWidget {
  const _FilterTabsBar({
    required this.filters,
    required this.active,
    required this.onSelect,
  });
  final List<String> filters;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  State<_FilterTabsBar> createState() => _FilterTabsBarState();
}

class _FilterTabsBarState extends State<_FilterTabsBar> {
  late List<GlobalKey> _keys;
  // The strip owns its OWN horizontal controller so centring the active chip
  // never reaches the outer vertical CustomScrollView. (The old
  // `Scrollable.ensureVisible` revealed the chip in EVERY ancestor scrollable,
  // so it yanked the whole page vertically — fighting the tab-tap pin-scroll.)
  final ScrollController _strip = ScrollController();

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.filters.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerActive());
  }

  @override
  void didUpdateWidget(covariant _FilterTabsBar old) {
    super.didUpdateWidget(old);
    if (old.filters.length != widget.filters.length) {
      _keys = List.generate(widget.filters.length, (_) => GlobalKey());
    }
    if (old.active != widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerActive());
    }
  }

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  /// Centre the active chip within the horizontal strip ONLY — compute the
  /// chip's centre in the strip's content coordinates and animate the strip's
  /// own controller. Never calls `Scrollable.ensureVisible`, so the outer
  /// vertical scroll is untouched.
  void _centerActive() {
    if (!_strip.hasClients ||
        widget.active < 0 ||
        widget.active >= _keys.length) {
      return;
    }
    final chipCtx = _keys[widget.active].currentContext;
    final selfBox = context.findRenderObject();
    if (chipCtx == null || selfBox is! RenderBox) return;
    final chipBox = chipCtx.findRenderObject();
    if (chipBox is! RenderBox) return;
    final chipLeftLocal = selfBox
        .globalToLocal(chipBox.localToGlobal(Offset.zero))
        .dx;
    final chipCentre = _strip.offset + chipLeftLocal + chipBox.size.width / 2;
    final target = (chipCentre - selfBox.size.width / 2).clamp(
      0.0,
      _strip.position.maxScrollExtent,
    );
    _strip.animateTo(
      target,
      duration: MotionGuard.duration(context, AppMotion.page),
      curve: AppMotion.signature,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mediumBackground,
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s12),
      child: SizedBox(
        height: 28,
        child: ListView.separated(
          controller: _strip,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin,
          ),
          itemCount: widget.filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (_, i) {
            final selected = i == widget.active;
            return GestureDetector(
              key: _keys[i],
              onTap: () => widget.onSelect(i),
              child: Container(
                height: 28,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSize.r14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  widget.filters[i],
                  style: TextStyle(
                    fontSize: AppSize.font12,
                    fontWeight: selected
                        ? AppTextStyles.bold
                        : AppTextStyles.regular,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Promotional channels strip (jm3eia feature collections as Jameia pills) ─────
class _ChannelsStrip extends StatelessWidget {
  const _ChannelsStrip({required this.channels});
  final List<({String id, String name})> channels;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.mediumBackground,
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s4),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin,
          ),
          itemCount: channels.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (context, i) {
            final c = channels[i];
            return GestureDetector(
              onTap: () => context.push(Routes.channelList, extra: c.name),
              child: Container(
                height: 34,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r3),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
