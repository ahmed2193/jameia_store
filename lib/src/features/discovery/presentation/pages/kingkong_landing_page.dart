import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/scroll_to_top_fab.dart';
import '../../../../core/design/jameia_icons.dart';
import '../cubit/kingkong_landing_cubit.dart';
import '../util/shop_model_bridge.dart';

/// Jameia `homepage_kingkong_page` (`category/kingKongPage`) — the category
/// landing reached by tapping a KingKong icon on the home grid.
///
/// 1:1 clone of the category landing: a category-title app bar (the tapped
/// channel name + search action), a horizontal **sub-category chip** rail, then
/// the [ShopCard] feed pulled from [JameiaRepository.shops] via a
/// [ListView.builder]. A scroll-to-top FAB fades in once the feed is scrolled;
/// tapping a card opens [Routes.shop].
class KingKongLandingPage extends StatelessWidget {
  const KingKongLandingPage({
    super.key,
    this.categoryId = 'k1',
    this.title = 'Food',
  });

  /// KingKong item id from the tapped home icon — selects the base shop pool.
  final String categoryId;

  /// Category title shown in the app bar (the tapped KingKong channel name).
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<KingKongLandingCubit>()..load(categoryId),
      child: _KingKongLandingView(title: title),
    );
  }
}

class _KingKongLandingView extends StatefulWidget {
  const _KingKongLandingView({required this.title});
  final String title;

  @override
  State<_KingKongLandingView> createState() => _KingKongLandingViewState();
}

class _KingKongLandingViewState extends State<_KingKongLandingView> {
  final ScrollController _controller = ScrollController();

  void _openShop(String shopId) => context.push(Routes.shop, extra: shopId);

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
          icon: const Icon(JameiaIcons.back, size: 20),
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
            icon: const Icon(JameiaIcons.search, size: 20),
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),
      floatingActionButton: ScrollToTopFab(controller: _controller),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: Column(
            children: [
              const _SubCategoryRail(),
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

/// Horizontal sub-category chip rail under the category title.
class _SubCategoryRail extends StatelessWidget {
  const _SubCategoryRail();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KingKongLandingCubit, KingKongLandingState>(
      buildWhen: (a, b) => a.activeSub != b.activeSub,
      builder: (context, state) {
        final cubit = context.read<KingKongLandingCubit>();
        return Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.pageMargin,
              ),
              itemCount: state.subCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
              itemBuilder: (_, i) => _SubChip(
                label: state.subCategories[i],
                selected: i == state.activeSub,
                onTap: () => cubit.selectSub(i),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubChip extends StatelessWidget {
  const _SubChip({
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

/// The [ShopCard] feed — a [ListView.builder] so off-screen cards never build.
class _ShopFeed extends StatelessWidget {
  const _ShopFeed({required this.onOpenShop, required this.controller});
  final ValueChanged<String> onOpenShop;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KingKongLandingCubit, KingKongLandingState>(
      buildWhen: (a, b) => a.shops != b.shops,
      builder: (context, state) {
        if (state.shops.isEmpty) {
          return EmptyStateView(
            message: 'discovery.no_shops_in_category'.tr(),
            icon: Icons.storefront_outlined,
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
