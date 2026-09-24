import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/scroll_to_top_fab.dart';
import '../cubit/meal_for_one_cubit.dart';
import '../util/shop_model_bridge.dart';

/// Jameia `mach_pro_sailor_c_meal_for_one_main` — the "Meal for One" curated
/// single-person-meal channel (v0.0.28, C-PAGE).
///
/// 1:1 clone of the channel surface described in `14_mach_pages.md` §2.18:
/// it reuses the same shop-card / scene-tab / filter-bar asset family as
/// `channel_list_main`, plus the channel-specific affordances the bundle exposes
/// (`handleOnRuleClick`, `handleOnShareClick`).
///
/// Layout (top → bottom):
///   • collapsing brand banner header (channel hero) with floating back +
///     `share` / `rules` actions in the app bar (`handleOnShareClick` /
///     `handleOnRuleClick`),
///   • a row of filter chips (`filterId` / `filterDisplayName`),
///   • the [ShopCard] feed pulled from [JameiaRepository.shops] via slivers,
///   • a scroll-to-top FAB ("to-top" button).
///
/// Tapping a card opens [Routes.shop]. State is served through a page-scoped
/// [MealForOneCubit] resolved from the service locator.
class MealForOnePage extends StatelessWidget {
  const MealForOnePage({super.key, this.title = 'Meal for One'});

  /// Channel title shown in the collapsed app bar.
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MealForOneCubit>(),
      child: _MealForOneView(title: title),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _MealForOneView extends StatefulWidget {
  const _MealForOneView({required this.title});
  final String title;

  @override
  State<_MealForOneView> createState() => _MealForOneViewState();
}

class _MealForOneViewState extends State<_MealForOneView> {
  final ScrollController _controller = ScrollController();

  void _openShop(String shopId) => context.push(Routes.shop, extra: shopId);

  /// `handleOnShareClick` — share affordance in the app bar.
  void _onShare() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('discovery.share_this_channel'.tr())),
      );
  }

  /// `handleOnRuleClick` — channel rules bottom sheet.
  void _onRules() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => const _RulesSheet(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      floatingActionButton: ScrollToTopFab(controller: _controller),
      body: SafeArea(
        bottom: false,
        child: ContentClamp(
          child: CustomScrollView(
            controller: _controller,
            slivers: [
              _BannerHeader(
                title: widget.title,
                onShare: _onShare,
                onRules: _onRules,
              ),
              const SliverToBoxAdapter(child: _FilterBar()),
              const SliverToBoxAdapter(child: ThinDivider()),
              _ShopFeed(onOpenShop: _openShop),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Brand banner header (collapsing channel hero) ─────────────────────────────

class _BannerHeader extends StatelessWidget {
  const _BannerHeader({
    required this.title,
    required this.onShare,
    required this.onRules,
  });

  final String title;
  final VoidCallback onShare;
  final VoidCallback onRules;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 168,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.brandForeground,
      surfaceTintColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(JameiaIcons.back, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        title,
        style: AppTextStyles.headingLarge.copyWith(
          color: AppColors.brandForeground,
          fontWeight: AppTextStyles.bold,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'discovery.tooltip_rules'.tr(),
          icon: const Icon(JameiaIcons.info, size: 20),
          onPressed: onRules,
        ),
        IconButton(
          tooltip: 'discovery.tooltip_share'.tr(),
          icon: const Icon(JameiaIcons.share, size: 20),
          onPressed: onShare,
        ),
        const SizedBox(width: AppSpacing.s4),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        background: _BannerBackground(),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

/// The channel hero behind the collapsing app bar.
///
/// Primary: [JameiaAssets.homeHeaderDefaultBg] rendered as a full-bleed asset
/// image with a bottom-anchored dark scrim (gradient from transparent → 80%
/// black) and a white headline + subtitle overlay flush to the bottom edge.
///
/// Fallback: when [_channelBannerAsset] is empty the gradient used in the
/// original implementation is shown instead so the screen never looks broken.
class _BannerBackground extends StatelessWidget {
  const _BannerBackground();

  /// The JameiaAssets path used as the channel banner.  Swap to any other
  /// `JameiaAssets.*` constant (e.g. [JameiaAssets.placeholder16x9]) to change
  /// the illustration.  An empty string triggers the gradient fallback.
  static const String _channelBannerAsset = JameiaAssets.homeHeaderDefaultBg;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Background layer — real channel image or gradient fallback ────
        if (_channelBannerAsset.isNotEmpty)
          Image.asset(
            _channelBannerAsset,
            fit: BoxFit.cover,
            // Graceful: if the asset is missing at runtime fall back to a
            // solid brand colour so the sliver stays consistent.
            errorBuilder: (_, e, st) =>
                const ColoredBox(color: AppColors.brandDarkBg),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topCenter,
                end: AlignmentDirectional.bottomCenter,
                colors: [AppColors.brandDarkBg, AppColors.primary],
              ),
            ),
          ),

        // ── 2. Dark scrim — bottom-anchored gradient so text stays readable ──
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              // transparent at top, 80% black at bottom
              colors: [AppColors.overlayDivider, AppColors.overlayPrimary],
              stops: [0.35, 1.0],
            ),
          ),
        ),

        // ── 3. Headline + subtitle flush to the bottom of the hero ──────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.pageMargin,
              AppSpacing.s48,
              AppSpacing.pageMargin,
              AppSpacing.s16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'discovery.meal_for_one_title'.tr(),
                  style: AppTextStyles.displayMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'discovery.meal_for_one_subtitle'.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealForOneCubit, MealForOneState>(
      buildWhen: (a, b) => a.activeFilter != b.activeFilter,
      builder: (context, state) {
        final cubit = context.read<MealForOneCubit>();
        return Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.pageMargin,
              ),
              itemCount: state.filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
              itemBuilder: (_, i) => _FilterChip(
                label: state.filters[i].tr(),
                selected: i == state.activeFilter,
                onTap: () => cubit.selectFilter(i),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: PopScale(
        popKey: selected,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s14,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.mediumBackground,
            // Bundle styles.digest a24a16: 'border-radius: 8dp' for filter chips.
            // AppRadius.r8 is a mislabeled alias (= 1dp), so use the literal 8dp.
            borderRadius: BorderRadius.circular(AppSize.r8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.captionLarge.copyWith(
              fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
              color: selected
                  ? AppColors.brandForeground
                  : AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shop feed ─────────────────────────────────────────────────────────────────

/// The curated [ShopCard] feed — a [SliverList.separated] so off-screen cards
/// never build.
class _ShopFeed extends StatelessWidget {
  const _ShopFeed({required this.onOpenShop});
  final ValueChanged<String> onOpenShop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealForOneCubit, MealForOneState>(
      buildWhen: (a, b) => a.shops != b.shops,
      builder: (context, state) {
        if (state.shops.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _NotServiceState(),
          );
        }
        return SliverList.separated(
          itemCount: state.shops.length,
          separatorBuilder: (_, _) =>
              const ThinDivider(indent: AppSpacing.pageMargin),
          itemBuilder: (_, i) {
            // TODO(P2.9-boundary): ShopCard is a shared core/widgets API that
            // requires the core Shop DTO, so reconstruct it from the entity at
            // this boundary instead of leaking ShopEntity into the shared widget.
            final shop = state.shops[i].toModel();
            return StaggerEntrance(
              index: i,
              child: ColoredBox(
                color: AppColors.white,
                child: ShopCard(shop: shop, onTap: () => onOpenShop(shop.id)),
              ),
            );
          },
        );
      },
    );
  }
}

/// Empty / not-serviceable state for the channel feed. Renders the shipped
/// branded [JameiaAssets.homeGuideNotService] illustration (assets.list.txt:
/// `guide_not_service_vf8g9z.png`) instead of a generic Material icon — the
/// same asset `channel_list` uses for not-serviceable regions.
class _NotServiceState extends StatelessWidget {
  const _NotServiceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              JameiaAssets.homeGuideNotService,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, e, st) => const Icon(
                Icons.ramen_dining_outlined,
                size: 56,
                color: AppColors.tertiaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'discovery.no_meals_for_one'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Channel rules sheet (`handleOnRuleClick`) ─────────────────────────────────

class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  static List<String> get _rules => <String>[
    'discovery.rule_portioned'.tr(),
    'discovery.rule_prices_change'.tr(),
    'discovery.rule_fees_terms'.tr(),
    'discovery.rule_no_combine'.tr(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  JameiaIcons.info,
                  size: 20,
                  color: AppColors.primaryText,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'discovery.channel_rules'.tr(),
                  style: AppTextStyles.headingLarge.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(JameiaIcons.close, size: 18),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final rule in _rules) _RuleRow(text: rule),
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              label: 'discovery.got_it'.tr(),
              onPressed: () => Navigator.maybePop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: AppSpacing.s2),
            child: Icon(
              JameiaIcons.confirm,
              size: 14,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scroll-to-top FAB ─────────────────────────────────────────────────────────
