import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, RenderSliver, ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/motion/motion.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/repositories/shop_repository.dart';
import '../cubit/shop_menu_cubit.dart';
import '../widgets/cart_bar.dart';
import '../widgets/section_list.dart';
import '../widgets/shop_hero.dart';

/// Jameia shop/menu screen — Jameia visual style, jm3eia products_screen DATA FLOW.
///
/// FLOW (jm3eia products_screen):
///   category → its [JameiaSubCategory]s become sub-tabs → each tab shows either
///     • a rank rail + sectioned list (one section per [JameiaRank]), or
///     • a plain product list ([JameiaSubCategory.directProducts]) when the sub
///       has no ranks (`hasRanks == false`).
///
/// ── Architecture (rebuilt as ONE CustomScrollView) ───────────────────────────
/// The whole shop is a SINGLE [CustomScrollView] driven by ONE [ScrollController]
/// (ported from the restaurant reference). The slivers, in order, are:
///   1. Collapsing pinned hero  ([ShopHeroHeader])      — cover + chrome row.
///   2. Meta card               ([ShopMetaCard])        — normal scroll-away.
///   3. Coupon strip            ([ShopCouponStrip])     — when present.
///   4. Sub-category tab bar    ([SubTabBarSliver])     — pinned, when >1 sub.
///   5. Rank rail               ([RankRailSliver])      — pinned, active sub >1 rank.
///   6. One section sliver per rank, each header carrying a [GlobalKey] so the
///      scroll-spy can `getOffsetToReveal` it.
///   7. Bottom padding so the last section can scroll under the pinned bars.
///
/// The hero collapses NATIVELY via the persistent-header `shrinkOffset` (no faked
/// collapse notifier any more). The sub-tabs are a JUMP/SWAP control (NOT a
/// TabBarView): tapping sub `s` swaps the body to sub `s`'s rail + sections and
/// AUTO-SCROLLS TO THE TOP so the new tab opens from its first section. The rank
/// rail and body stay in two-way sync via scroll-spy:
///   • scroll → [_onScroll] → [_activeSectionIndex] → `cubit.reportActiveRank`.
///   • rank tap → [_scrollToSection] (getOffsetToReveal + converge/settle loop,
///     guarded by `_programmaticScroll` + `_scrollGen`).
///
/// VIP/Mart pricing, cart wiring, sku sheet and the `catId~subId~rankId`
/// deep-link all behave exactly as before.

/// Builds the [Routes.shop] argument string. A plain category id opens the shop
/// at its first tab; the `catId~subId~rankId` form deep-links to a sub-category
/// tab + rank (used when opening a product from a home featured rail). Encoded as
/// one String because [Routes.shop] carries a String arg. Trailing empty
/// segments are trimmed so a sub with no rank stays `catId~subId`, and a plain
/// category (no sub + no rank) stays just `categoryId`.
String shopRouteArg(String categoryId, {String? subId, String? rankId}) {
  if (subId == null || subId.isEmpty) return categoryId;
  final rank = rankId == null || rankId.isEmpty ? '' : '~$rankId';
  return '$categoryId~$subId$rank';
}

class ShopPage extends StatelessWidget {
  const ShopPage({
    super.key,
    required this.shopId,
    this.initialSubId,
    this.initialRankId,
  });

  /// Routing passes the CATEGORY id here — a plain id, or the deep-link form
  /// `catId~subId~rankId` (see [shopRouteArg]) to open on a specific
  /// sub-category tab + rank.
  final String shopId;

  /// Optional deep-link override (used by tests / direct construction).
  final String? initialSubId;

  /// Optional deep-link rank override (used by tests / direct construction).
  final String? initialRankId;

  @override
  Widget build(BuildContext context) {
    // Sync boundary reads through the feature repository (the menu graph stays
    // in core `Shop` / `JameiaCategory` because its product rows push the core
    // `Product` across features) — no direct `JameiaRepository` reach-in.
    final repo = sl<ShopRepository>();
    // Decode the (possibly composite) route arg.
    final parts = shopId.split('~');
    final catId = parts[0];
    final subId =
        initialSubId ??
        (parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null);
    final rankId =
        initialRankId ??
        (parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null);

    // Derived Shop carries hero/meta/coupon metrics (rating, min-order, …).
    final shop = repo.shopById(catId);
    if (shop == null) {
      // Unknown shop id (stale deep link / bad promo card) → not-found instead
      // of silently opening the wrong store.
      return Scaffold(
        backgroundColor: AppColors.mediumBackground,
        body: ErrorView(onRetry: () => Navigator.maybePop(context)),
      );
    }
    // Resolve the real jameia category for the tab/rank structure. Fall back to
    // a single-tab view built from the derived Shop sections so it never crashes.
    final cat = repo.categoryById(catId);

    return Scaffold(
      // real Jameia shop page background: #F5F6FA (system-color-neutral-largeBackground)
      backgroundColor: AppColors.mediumBackground,
      body: _ShopMenu(
        shop: shop,
        category: cat,
        initialSubId: subId,
        initialRankId: rankId,
      ),
      bottomNavigationBar: CartBar(shop: shop),
    );
  }
}

// ── Shop menu (single CustomScrollView + scroll-spy) ──────────────────────────
class _ShopMenu extends StatefulWidget {
  const _ShopMenu({
    required this.shop,
    required this.category,
    this.initialSubId,
    this.initialRankId,
  });
  final Shop shop;
  final JameiaCategory? category;
  final String? initialSubId;
  final String? initialRankId;

  @override
  State<_ShopMenu> createState() => _ShopMenuState();
}

class _ShopMenuState extends State<_ShopMenu> with TickerProviderStateMixin {
  // ── One scroll controller + one coordination cubit for the whole menu ───────
  final ScrollController _scroll = ScrollController();
  final ScrollController _railController = ScrollController();
  // Key on the pinned sub-tab bar so a sub-tab tap can dock it right under the
  // collapsed hero (the new tab's list then starts under the pinned tabs).
  final GlobalKey _subTabKey = GlobalKey();
  late final ShopMenuCubit _menu;

  /// Drives a one-shot, compositor-only (opacity) fade-in of the body when a
  /// sub-tab is swapped — paint-only, so it never touches layout / scroll-spy.
  /// Starts at 1 (first mount is already visible); replays 0→1 on each swap.
  late final AnimationController _bodyFade;

  late final List<JameiaSubCategory> _subs;
  late int _activeSubIndex;
  TabController? _tabController;

  // The active sub's sections (one per rank) + a GlobalKey per section header,
  // rebuilt whenever the active sub changes (so scroll-spy targets the right set).
  List<MenuSection> _sections = const [];
  List<GlobalKey> _sectionKeys = const [];

  // Deep-link rank (only honoured on the initial sub).
  String? _pendingRankId;

  // ── Scroll-spy guards (ported from the restaurant reference) ────────────────
  /// Set while a programmatic scroll (rank tap / sub swap) is running, so the
  /// scroll-spy doesn't fight it and bounce the active rank.
  bool _programmaticScroll = false;

  /// Monotonic id so a newer scroll-to supersedes any in-flight one (repeated
  /// taps must not spawn overlapping loops that fight over the scroll position).
  int _scrollGen = 0;

  // Rail item extents (match the ListView itemExtent in [RankRail]).
  static const double _railItemImage = 82.5;
  static const double _railItemText = 96;

  bool get _hasSubTabs => _subs.length > 1;
  bool get _hasRanks => _subs[_activeSubIndex].hasRanks;
  bool get _hasImages => _sections.any((s) => s.image.isNotEmpty);
  double get _railItemExtent => _hasImages ? _railItemImage : _railItemText;
  bool get _showRail => _hasRanks && _sections.length > 1;

  @override
  void initState() {
    super.initState();
    _subs = _resolveSubs();
    final idx = widget.initialSubId == null
        ? 0
        : _subs.indexWhere((s) => s.id == widget.initialSubId);
    _activeSubIndex = idx < 0 ? 0 : idx;
    _pendingRankId = widget.initialRankId;
    _menu = ShopMenuCubit(initialTabIndex: _activeSubIndex);
    _bodyFade = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
      value: 1, // first mount is already fully visible
    );
    if (_hasSubTabs) {
      _tabController = TabController(
        length: _subs.length,
        vsync: this,
        initialIndex: _activeSubIndex,
      )..addListener(_onTabChanged);
    }
    _rebuildSections();
    _scroll.addListener(_onScroll);

    // Deep-link: after first layout, scroll to the requested rank (if any).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rankId = _pendingRankId;
      if (rankId == null || rankId.isEmpty) return;
      final i = _sections.indexWhere((s) => s.id == rankId);
      if (i > 0) {
        _menu.activeRank.value = i;
        _scrollToSection(i);
      }
    });
  }

  /// Sub-categories that become tabs. When there is no jameia category (fallback)
  /// we synthesize a single sub whose ranks are the derived Shop sections, so the
  /// existing rail + section mechanics keep working.
  List<JameiaSubCategory> _resolveSubs() {
    final cat = widget.category;
    if (cat != null && cat.subs.isNotEmpty) return cat.subs;
    return [
      JameiaSubCategory(
        id: widget.shop.id,
        name: widget.shop.name,
        nameAr: widget.shop.nameAr,
        ranks: [
          for (final s in widget.shop.sections)
            JameiaRank(
              id: s.id,
              name: s.title,
              nameAr: s.title,
              image: s.image,
              count: s.products.length,
              products: s.products,
            ),
        ],
      ),
    ];
  }

  /// Build the active sub's sections + fresh section keys.
  void _rebuildSections() {
    final sub = _subs[_activeSubIndex];
    _sections = [
      for (final r in sub.ranks)
        MenuSection(
          id: r.id,
          title: r.displayName,
          image: r.image,
          products: r.products,
        ),
    ];
    _sectionKeys = [for (int i = 0; i < _sections.length; i++) GlobalKey()];
  }

  void _onTabChanged() {
    final c = _tabController;
    if (c == null) return;
    if (c.index == _activeSubIndex) return;
    // The indicator already moved on tap; swap the body to the new sub.
    _swapSub(c.index);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _railController.dispose();
    _bodyFade.dispose();
    _menu.close();
    super.dispose();
  }

  // ── Sub-tab swap ────────────────────────────────────────────────────────────

  /// Swap the body to sub [index] and AUTO-SCROLL so the pinned sub-tab bar docks
  /// right under the collapsed hero — the new tab opens from its first section,
  /// directly under the tabs (the tabs stay put; the hero does NOT re-expand).
  ///
  /// The dock offset is the sub-tab sliver's `precedingScrollExtent` (expanded
  /// hero + meta + coupon) minus the collapsed hero extent (status-bar inset +
  /// [kCompactBar]). This is a fixed offset independent of the new sub's length.
  ///
  /// Performance: animating across a long list rebuilds every sliver each frame,
  /// so for a far scroll we first `jumpTo` within ~1 screen of the target
  /// (instant — no intermediate sliver builds) and only ANIMATE the final
  /// screen. `_programmaticScroll` + `_scrollGen` guard the scroll-spy and let a
  /// newer tap supersede this one.
  Future<void> _swapSub(int index) async {
    if (index < 0 || index >= _subs.length || index == _activeSubIndex) return;
    HapticFeedback.selectionClick(); // crisp tactile tick on tab change
    _pendingRankId = null; // deep-link rank only applies to the initial sub
    final gen = ++_scrollGen; // a newer tap supersedes this run
    _programmaticScroll = true; // don't let scroll-spy fight the reset
    setState(() {
      _activeSubIndex = index;
      _rebuildSections();
    });
    _menu.selectTab(index); // resets activeRank → 0
    _bodyFade.forward(from: 0); // gentle fade-in of the new sub's sections

    // Let the new body lay out, then dock the tabs under the collapsed hero.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || gen != _scrollGen || !_scroll.hasClients) {
      if (mounted && gen == _scrollGen) _programmaticScroll = false;
      return;
    }
    final target = _subTabDockOffset();
    if (target != null && (target - _scroll.offset).abs() > 1) {
      final vp = _scroll.position.viewportDimension;
      // Far from target → jump within ~1 screen first (instant), so the visible
      // animation only spans the final screen instead of the whole list.
      if ((target - _scroll.offset).abs() > vp * 1.5) {
        final near = (target > _scroll.offset ? target - vp : target + vp)
            .clamp(0.0, _scroll.position.maxScrollExtent);
        _scroll.jumpTo(near);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || gen != _scrollGen || !_scroll.hasClients) {
          if (mounted && gen == _scrollGen) _programmaticScroll = false;
          return;
        }
      }
      await _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: MotionGuard.curve(context, AppMotion.standard),
      );
    }
    if (!mounted || gen != _scrollGen) return;
    _programmaticScroll = false;
  }

  /// Scroll offset at which the pinned sub-tab bar docks flush under the
  /// collapsed hero (status-bar inset + [kCompactBar]). Null until laid out.
  double? _subTabDockOffset() {
    final ro = _subTabKey.currentContext?.findRenderObject();
    if (ro is! RenderSliver) return null;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return (ro.constraints.precedingScrollExtent - (topInset + kCompactBar))
        .clamp(0.0, _scroll.position.maxScrollExtent);
  }

  /// Re-tap of the ALREADY-active sub-tab → just dock the tab bar under the hero
  /// (no body swap). Guarded like [_swapSub] so the scroll-spy won't fight it.
  Future<void> _dockSubTabs() async {
    if (!_scroll.hasClients) return;
    final gen = ++_scrollGen;
    _programmaticScroll = true;
    final target = _subTabDockOffset();
    if (target != null && (target - _scroll.offset).abs() > 1) {
      await _scroll.animateTo(
        target,
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: MotionGuard.curve(context, AppMotion.standard),
      );
    }
    if (!mounted || gen != _scrollGen) return;
    _programmaticScroll = false;
  }

  // ── Scroll-spy + rank navigation (ported from the restaurant reference) ─────
  void _onScroll() {
    if (_programmaticScroll || _sectionKeys.isEmpty || !_showRail) return;
    final idx = _activeSectionIndex();
    final before = _menu.activeRank.value;
    _menu.reportActiveRank(idx);
    if (_menu.activeRank.value != before) _scrollRailToCenter(idx);
  }

  /// Scroll offset at which section [i]'s top sits flush UNDER the pinned bars,
  /// or null when it isn't laid out yet. `getOffsetToReveal(_, 0.0)` ALREADY
  /// subtracts the obstruction extent of the pinned slivers (hero + tab bar +
  /// rail), so the returned offset lands the section flush under the bars — do
  /// NOT subtract the pinned extents again.
  double? _revealOf(int i) {
    if (i < 0 || i >= _sectionKeys.length) return null;
    final box = _sectionKeys[i].currentContext?.findRenderObject();
    if (box == null) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0.0).offset;
  }

  /// Weighted estimate of (an unbuilt) section [i]'s offset for the initial far
  /// jump under lazy rendering — product counts make a big section estimate
  /// proportionally taller, so the jump lands close and getOffsetToReveal then
  /// snaps it flush. Falls back to a uniform `i / n`.
  double _estimateOffset(int i, double maxExtent) {
    final n = _sectionKeys.length;
    if (n == 0) return 0;
    double total = 0;
    for (final s in _sections) {
      total += s.products.length + 1;
    }
    if (total > 0) {
      double cum = 0;
      for (int k = 0; k < i && k < _sections.length; k++) {
        cum += _sections[k].products.length + 1;
      }
      return maxExtent * (cum / total);
    }
    return maxExtent * (i / n);
  }

  int _activeSectionIndex() {
    final offset = _scroll.offset;
    int active = 0;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final reveal = _revealOf(i);
      if (reveal == null) continue;
      if (reveal <= offset + 1) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }

  /// Tap a rail item → scroll so section [i] sits flush under the pinned bars.
  /// Guarded by `_programmaticScroll` + `_scrollGen` so the body→rail sync won't
  /// fight the in-flight animation, and a newer tap supersedes an older one.
  Future<void> _scrollToSection(int i) async {
    if (i < 0 || i >= _sectionKeys.length) return;
    HapticFeedback.lightImpact();
    final gen = ++_scrollGen; // a newer tap supersedes this run
    _programmaticScroll = true;
    _menu.selectRank(i, userInitiated: true);
    _scrollRailToCenter(i);

    if (!_scroll.hasClients) {
      _programmaticScroll = false;
      return;
    }

    // NEAR target (built + within ~1.5 screens) → one quick smooth animate.
    // FAR / not-built → instant jump-converge (re-measure each frame as lazy
    // slivers build). Both paths finish with a precise snap.
    final viewport = _scroll.position.viewportDimension;
    final initial = _revealOf(i);
    if (initial != null && (initial - _scroll.offset).abs() <= viewport * 1.5) {
      final dest = initial.clamp(0.0, _scroll.position.maxScrollExtent);
      if ((dest - _scroll.offset).abs() > 1) {
        await _scroll.animateTo(
          dest,
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: MotionGuard.curve(context, AppMotion.standard),
        );
      }
      if (!mounted || gen != _scrollGen) return; // superseded
    } else {
      for (int attempt = 0; attempt < 8; attempt++) {
        if (!_scroll.hasClients) break;
        final t = _revealOf(i);
        if (t != null && (t - _scroll.offset).abs() <= 1) break;
        final dest = (t ?? _estimateOffset(i, _scroll.position.maxScrollExtent))
            .clamp(0.0, _scroll.position.maxScrollExtent);
        if ((dest - _scroll.offset).abs() > 1) _scroll.jumpTo(dest);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || gen != _scrollGen) return; // superseded
      }
    }

    // SETTLE — lazy slivers above the target re-estimate their extent once they
    // scroll out of cache, shifting the target after we first land. Re-snap each
    // frame until the target offset stops moving (stable across two frames).
    double prev = double.nan;
    for (int s = 0; s < 6; s++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || gen != _scrollGen) return; // superseded
      if (!_scroll.hasClients) break;
      final t = _revealOf(i);
      if (t == null) break;
      final dest = t.clamp(0.0, _scroll.position.maxScrollExtent);
      final offBy = (dest - _scroll.offset).abs();
      final stable = (dest - prev).abs() <= 1;
      if (offBy > 1) _scroll.jumpTo(dest);
      if (offBy <= 1 && stable) break;
      prev = dest;
    }

    // Release the lock a frame later, and only if WE are still the latest run.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || gen != _scrollGen) return;
    _programmaticScroll = false;
  }

  void _scrollRailToCenter(int index) {
    if (!_railController.hasClients) return;
    try {
      final double itemWidth = _railItemExtent;
      final double screenWidth = MediaQuery.sizeOf(context).width;
      final target = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _railController.animateTo(
        target.clamp(0.0, _railController.position.maxScrollExtent),
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: MotionGuard.curve(context, AppMotion.standard),
      );
    } catch (_) {
      /* clients detached mid-animation */
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final hasCoupon = shop.promo.isNotEmpty || shop.freeDelivery;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
      slivers: [
        // 1) Collapsing pinned hero — cover + chrome row.
        ShopHeroHeader(shop: shop),
        // 2) Meta card (normal scroll-away).
        SliverToBoxAdapter(child: ShopMetaCard(shop: shop)),
        // 3) Coupon strip (when present).
        if (hasCoupon) SliverToBoxAdapter(child: ShopCouponStrip(shop: shop)),
        // 4) Sub-category tab bar (pinned, only when >1 sub). Switching subs is
        //    driven by the TabController listener (_onTabChanged → _swapSub);
        //    onTap ALSO catches a re-tap of the ACTIVE tab so "any tap" docks.
        if (_hasSubTabs)
          SubTabBarSliver(
            key: _subTabKey,
            controller: _tabController!,
            subs: _subs,
            onTap: (i) {
              if (i == _activeSubIndex) _dockSubTabs();
            },
          ),
        // 5 + 6) Active sub's body: rail (pinned) + section slivers, OR a
        //        direct product list / empty fallback.
        ..._bodySlivers(),
        // 7) Bottom padding so the last section can scroll under the pinned bars
        //    (required for scroll-spy to reach the last rank).
        SliverToBoxAdapter(child: SizedBox(height: 120 + bottomInset)),
      ],
    );
  }

  List<Widget> _bodySlivers() {
    final shop = widget.shop;
    // 0-rank sub → direct product list (no rail) or empty message.
    if (!_hasRanks) {
      final products = _subs[_activeSubIndex].directProducts;
      if (products.isEmpty) {
        return const [SliverToBoxAdapter(child: EmptySubMessage())];
      }
      return [
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _bodyFade,
            child: DirectProductsCard(products: products, shop: shop),
          ),
        ),
      ];
    }
    return [
      // 5) Pinned rank rail for the active sub (only when >1 rank).
      if (_showRail)
        RankRailSliver(
          // Key per active sub so the rail rebuilds on a swap.
          key: ValueKey('rail_${_subs[_activeSubIndex].id}'),
          sections: _sections,
          hasImages: _hasImages,
          activeRank: _menu.activeRank,
          controller: _railController,
          itemExtent: _railItemExtent,
          onSelect: _scrollToSection,
        ),
      // 6) One sliver per rank section; the header carries a GlobalKey for
      //    scroll-spy (getOffsetToReveal).
      for (int i = 0; i < _sections.length; i++)
        SliverToBoxAdapter(
          key: ValueKey(
            'section_${_subs[_activeSubIndex].id}_${_sections[i].id}',
          ),
          child: RepaintBoundary(
            child: KeyedSubtree(
              key: _sectionKeys[i],
              // Paint-only fade: getOffsetToReveal targets this box's LAYOUT,
              // which the opacity transform leaves untouched — scroll-spy safe.
              child: FadeTransition(
                opacity: _bodyFade,
                child: SectionCard(
                  index: i,
                  section: _sections[i],
                  shop: shop,
                  activeRank: _menu.activeRank,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}
