import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/scroll_to_top_fab.dart';
import '../cubit/pick_up_cubit.dart';
import '../util/shop_model_bridge.dart';

/// Jameia `mach_pro_sailor_c_pick_up_page_main` — the self-pickup shop list.
///
/// 1:1 clone of the pickup tab: a header note explaining you skip delivery and
/// collect the order yourself, a distance-sorted [ShopCard] feed (the shop-card
/// asset family backed by [PickUpCubit.pickUpShops]), and a scroll-to-top FAB
/// (`pick_up_btn_to_top`) that fades in once the feed is scrolled. Tapping a card
/// opens [Routes.shop].
///
/// There is no delivery-fee surface here (pickup = no delivery), so each card's
/// meta line emphasizes distance / walk; the page-scoped cubit is constructed
/// inline (never registered in the service locator).
class PickUpPage extends StatelessWidget {
  const PickUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PickUpCubit>(),
      child: const _PickUpView(),
    );
  }
}

class _PickUpView extends StatefulWidget {
  const _PickUpView();

  @override
  State<_PickUpView> createState() => _PickUpViewState();
}

class _PickUpViewState extends State<_PickUpView> {
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
          'discovery.self_pickup_title'.tr(),
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
          child: _ShopFeed(controller: _controller, onOpenShop: _openShop),
        ),
      ),
    );
  }
}

/// Header note: pickup skips delivery — collect the order from the shop yourself.
class _PickUpNote extends StatelessWidget {
  const _PickUpNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        AppSpacing.s12,
        AppSpacing.pageMargin,
        AppSpacing.s12,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.freeDeliveryBg,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.freeDelivery,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                JameiaIcons.storeLocation,
                size: 20,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'discovery.skip_delivery_fee_title'.tr(),
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.freeDelivery,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'discovery.skip_delivery_fee_body'.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sub-header above the feed: "Nearby for pickup" + a count of sorted shops.
class _NearbyHeader extends StatelessWidget {
  const _NearbyHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        AppSpacing.s4,
        AppSpacing.pageMargin,
        AppSpacing.s12,
      ),
      child: Row(
        children: [
          const Icon(
            JameiaIcons.location,
            size: 16,
            color: AppColors.primaryText,
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Text(
              'discovery.nearby_for_pickup'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          Text(
            'discovery.shops_count'.tr(namedArgs: {'count': '$count'}),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// The distance-sorted [ShopCard] feed — a [ListView.builder] so off-screen
/// cards never build. The note + sub-header ride along as the first two items so
/// they scroll with the list (and the scroll-to-top FAB tracks the same offset).
class _ShopFeed extends StatelessWidget {
  const _ShopFeed({required this.controller, required this.onOpenShop});
  final ScrollController controller;
  final ValueChanged<String> onOpenShop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PickUpCubit, PickUpState>(
      buildWhen: (a, b) => a.shops != b.shops,
      builder: (context, state) {
        final shops = state.shops;
        if (shops.isEmpty) {
          return EmptyStateView(
            message: 'discovery.no_pickup_shops'.tr(),
            icon: Icons.storefront_outlined,
          );
        }
        // 0 = note, 1 = nearby header, 2..N = shop cards.
        const leadingCount = 2;
        return ListView.builder(
          controller: controller,
          padding: const EdgeInsets.only(bottom: AppSpacing.s24),
          itemCount: shops.length + leadingCount,
          itemBuilder: (_, i) {
            if (i == 0) return const _PickUpNote();
            if (i == 1) return _NearbyHeader(count: shops.length);
            final cardIndex = i - leadingCount;
            // TODO(P2.9-boundary): _PickUpShopCard wraps the shared core ShopCard
            // widget (core Shop DTO), so reconstruct the DTO from the entity at
            // this boundary instead of leaking ShopEntity into the shared widget.
            final shop = shops[cardIndex].toModel();
            return StaggerEntrance(
              index: cardIndex,
              child: ColoredBox(
                color: AppColors.white,
                child: Column(
                  children: [
                    _PickUpShopCard(
                      shop: shop,
                      onTap: () => onOpenShop(shop.id),
                    ),
                    if (i < shops.length + leadingCount - 1)
                      const ThinDivider(indent: AppSpacing.pageMargin),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A [ShopCard] wrapped with a pickup-distance ribbon overlaid on the meta —
/// reuses the shared shop-card body, then appends a "Pick up · {distance}" pill
/// so the feed reads as pickup (no delivery surface).
class _PickUpShopCard extends StatelessWidget {
  const _PickUpShopCard({required this.shop, required this.onTap});
  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ShopCard(shop: shop, onTap: onTap),
        PositionedDirectional(
          end: AppSpacing.pageMargin,
          top: AppSpacing.s12 + 8,
          child: _PickUpBadge(distanceKm: shop.distanceKm),
        ),
      ],
    );
  }
}

class _PickUpBadge extends StatelessWidget {
  const _PickUpBadge({required this.distanceKm});
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.overlayPrimary,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            JameiaIcons.storeLocation,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: AppSpacing.s4),
          Text(
            'discovery.pick_up_distance'.tr(
              namedArgs: {'distance': Formatters.distance(distanceKm)},
            ),
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.white,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scroll-to-top FAB (`pick_up_btn_to_top`) — fades in once the feed is scrolled.
