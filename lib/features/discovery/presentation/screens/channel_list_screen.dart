import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/scroll_to_top_fab.dart';
import '../cubit/channel_list_cubit.dart';
import '../util/shop_model_bridge.dart';

/// KeeTa `channel_list_main` — the channel / category landing list.
///
/// Layout (top → bottom): an [AppBar] with the category title, a row of
/// scene-tab chips, a horizontal filter bar, then the [ShopCard] feed pulled
/// from [KeetaRepository.shops] via a [ListView.builder]. A scroll-to-top FAB
/// ("to-top" button) appears once the feed is scrolled; tapping a card opens
/// [Routes.shop].
class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key, this.title = 'Discover'});

  /// Category title shown in the app bar (e.g. the tapped KingKong channel).
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChannelListCubit>(),
      child: _ChannelListView(title: title),
    );
  }
}

class _ChannelListView extends StatefulWidget {
  const _ChannelListView({required this.title});
  final String title;

  @override
  State<_ChannelListView> createState() => _ChannelListViewState();
}

class _ChannelListViewState extends State<_ChannelListView> {
  final ScrollController _controller = ScrollController();

  void _openShop(String shopId) =>
      Navigator.pushNamed(context, Routes.shop, arguments: shopId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.title,
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(KeetaIcons.search, size: 20),
            onPressed: () => Navigator.pushNamed(context, Routes.search),
          ),
        ],
      ),
      floatingActionButton: ScrollToTopFab(controller: _controller),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: Column(
            children: [
              const _SceneTabs(),
              const _FilterBar(),
              const ThinDivider(),
              Expanded(
                child: _ShopFeed(
                  onOpenShop: _openShop,
                  controller: _controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scene-tab chips (`tab_selected*` / `scence_item_selected`) across the top.
class _SceneTabs extends StatelessWidget {
  const _SceneTabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelListCubit, ChannelListState>(
      buildWhen: (a, b) => a.activeScene != b.activeScene,
      builder: (context, state) {
        final cubit = context.read<ChannelListCubit>();
        return Container(
          color: AppColors.white,
          height: 44,
          alignment: AlignmentDirectional.centerStart,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            itemCount: state.scenes.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s20),
            itemBuilder: (_, i) => _SceneTab(
              label: state.scenes[i],
              selected: i == state.activeScene,
              onTap: () => cubit.selectScene(i),
            ),
          ),
        );
      },
    );
  }
}

class _SceneTab extends StatelessWidget {
  const _SceneTab({
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
              color: selected ? AppColors.primaryText : AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          PopScale(
            popKey: selected,
            child: AnimatedContainer(
              duration: MotionGuard.duration(context, AppMotion.fast),
              curve: AppMotion.signature,
              height: 3,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal filter bar (`filterId` / `filterDisplayName`) under the scene tabs.
class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelListCubit, ChannelListState>(
      buildWhen: (a, b) => a.activeFilter != b.activeFilter,
      builder: (context, state) {
        final cubit = context.read<ChannelListCubit>();
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
            borderRadius: BorderRadius.circular(AppRadius.r8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: AppSpacing.s4),
                  child: Icon(
                    KeetaIcons.filter,
                    size: 12,
                    color: AppColors.primaryText,
                  ),
                ),
              Text(
                label,
                style: AppTextStyles.captionLarge.copyWith(
                  fontWeight: selected
                      ? AppTextStyles.bold
                      : AppTextStyles.regular,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The [ShopCard] feed — a [ListView.builder] so off-screen cards never build.
class _ShopFeed extends StatelessWidget {
  const _ShopFeed({required this.onOpenShop, required this.controller});
  final ValueChanged<String> onOpenShop;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelListCubit, ChannelListState>(
      buildWhen: (a, b) => a.shops != b.shops,
      builder: (context, state) {
        if (state.shops.isEmpty) {
          return EmptyStateView(
            message: 'discovery.no_shops_in_channel'.tr(),
            icon: KeetaIcons.store,
          );
        }
        return ListView.separated(
          controller: controller,
          padding: const EdgeInsets.only(bottom: AppSpacing.s24),
          itemCount: state.shops.length,
          separatorBuilder: (_, _) =>
              const ThinDivider(indent: AppSpacing.pageMargin),
          itemBuilder: (_, i) {
            // TODO(P2.9-boundary): ShopCard is a shared core/widgets API that
            // requires the core Shop DTO, so reconstruct it from the entity at
            // this boundary instead of leaking ShopEntity into the shared widget.
            final shop = state.shops[i].toModel();
            return RepaintBoundary(
              child: StaggerEntrance(
                index: i,
                child: ColoredBox(
                  color: AppColors.white,
                  child: ShopCard(shop: shop, onTap: () => onOpenShop(shop.id)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Scroll-to-top FAB ("to-top" button) — fades in once the feed is scrolled.
