import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/widgets/quick_add.dart';
import '../cubit/fixed_price_cubit.dart';
import '../util/shop_model_bridge.dart';

/// KeeTa `mach_pro_sailor_c_fixed_price` — the fixed-price / flash ordering
/// channel (v0.0.88, C-PAGE).
///
/// A full ordering surface (not just a list). Layout (top → bottom):
///  • collapsing flash brand banner (hero) with a live countdown pill,
///  • a row of kcal / delivery-fee / time campaign badges,
///  • the hot-selling product GRID (`hot_selling_*`) of [ProductCard]s pulled
///    from one shop's [Shop.allProducts], each with a big campaign price, a
///    discount % flag and per-card add-to-cart via the global [CartCubit],
///  • a sticky cart bar identical to the shop screen, driving checkout.
///
/// The reference page is sourced from a single flash shop (KeeTa's fixed-price
/// channel is backed by one promo storefront). The page-scoped [FixedPriceCubit]
/// is resolved from the service locator and loaded with the optional [shopId].
class FixedPriceScreen extends StatelessWidget {
  const FixedPriceScreen({super.key, this.shopId});

  /// Optional shop id (router may pass the tapped flash storefront). When null
  /// the cubit picks the first grocery shop as the flash channel host.
  final String? shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FixedPriceCubit>()..load(shopId),
      child: const _FixedPriceView(),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _FixedPriceView extends StatelessWidget {
  const _FixedPriceView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FixedPriceCubit, FixedPriceState>(
      builder: (context, state) {
        final shopEntity = state.shop;
        if (shopEntity == null) {
          return Scaffold(
            backgroundColor: AppColors.mediumBackground,
            body: state.status == FixedPriceStatus.error
                ? ErrorView(
                    onRetry: () => context.read<FixedPriceCubit>().retry(),
                  )
                : const AppLoader(),
          );
        }
        // TODO(P2.9-boundary): the flash hero / hot-selling grid / cart bar all
        // wrap shared core widgets (KeetaImage, ProductCard) and the cross-
        // feature CartCubit, which require the core Shop / Product DTOs, so
        // reconstruct them from the entities at this boundary instead of leaking
        // ShopEntity / ProductEntity into the shared surfaces.
        final shop = shopEntity.toModel();
        final products = state.products.toModels();
        return Scaffold(
          backgroundColor: AppColors.mediumBackground,
          body: CustomScrollView(
            slivers: [
              _FlashHero(shop: shop),
              const SliverToBoxAdapter(child: _CampaignBadges()),
              const SliverToBoxAdapter(child: _HotSellingHeader()),
              _HotSellingGrid(shop: shop, products: products),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
          bottomNavigationBar: _CartBar(shop: shop),
        );
      },
    );
  }
}

// ── Flash brand banner (collapsing hero) ──────────────────────────────────────

class _FlashHero extends StatelessWidget {
  const _FlashHero({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 188,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.brandForeground,
      leading: const _CircleIcon(icon: KeetaIcons.back),
      actions: const [
        _CircleIcon(icon: KeetaIcons.share),
        _CircleIcon(icon: KeetaIcons.search),
        SizedBox(width: AppSpacing.s8),
      ],
      title: Text(
        'discovery.fixed_price_title'.tr(),
        style: AppTextStyles.headingLarge.copyWith(
          color: AppColors.brandForeground,
          fontWeight: AppTextStyles.bold,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Shop cover photo as the campaign backdrop.
            KeetaImage(url: shop.cover),
            // Brand-yellow wash so the white title stays legible.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.overlayPrimary, AppColors.overlayPrimary],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s16,
                  0,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          KeetaIcons.flame,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.s6),
                        Text(
                          'discovery.flash_deals'.tr(),
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.white,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        const _CountdownPill(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'discovery.fixed_price_channel_label'.tr(
                        namedArgs: {'shop': shop.displayName},
                      ),
                      maxLines: 1,
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
        ),
      ),
    );
  }
}

/// Live "ends in" countdown pill — counts down from a fixed start (2h 45m 10s),
/// formatted HH:MM:SS. Runs a [Timer.periodic] every second and disposes it in
/// [dispose]. Wrapped in [RepaintBoundary] so the 1 Hz tick never triggers a
/// repaint outside the pill.
class _CountdownPill extends StatefulWidget {
  const _CountdownPill();

  @override
  State<_CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<_CountdownPill> {
  // Fixed start: 2 h 45 m 10 s (matches the KeeTa reference screenshot value).
  static const int _startSeconds = 2 * 3600 + 45 * 60 + 10;

  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _startSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final h = _remaining ~/ 3600;
    final m = (_remaining % 3600) ~/ 60;
    final s = _remaining % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.r6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(KeetaIcons.time, size: 12, color: AppColors.white),
            const SizedBox(width: AppSpacing.s4),
            Text(
              'discovery.ends_in'.tr(namedArgs: {'time': _formatted}),
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.white,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.s8),
      child: GestureDetector(
        onTap: () => icon == KeetaIcons.back
            ? Navigator.maybePop(context)
            : icon == KeetaIcons.search
            ? Navigator.pushNamed(context, Routes.search)
            : null,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.overlayPrimary,
          child: Icon(icon, size: 18, color: AppColors.white),
        ),
      ),
    );
  }
}

// ── Campaign badges (kcal-saver / delivery-fee / time) ────────────────────────

class _CampaignBadges extends StatelessWidget {
  const _CampaignBadges();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        children: [
          Expanded(
            child: _Badge(
              icon: KeetaIcons.flame,
              title: 'discovery.badge_best_price_title'.tr(),
              subtitle: 'discovery.badge_best_price_subtitle'.tr(),
              tint: AppColors.finalPrice,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: _Badge(
              icon: KeetaIcons.delivery,
              title: 'discovery.badge_free_delivery_title'.tr(),
              subtitle: 'discovery.badge_free_delivery_subtitle'.tr(),
              tint: AppColors.freeDelivery,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: _Badge(
              icon: KeetaIcons.deliveryTime,
              title: 'discovery.badge_time_title'.tr(),
              subtitle: 'discovery.badge_time_subtitle'.tr(),
              tint: AppColors.warn,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: tint),
        const SizedBox(height: AppSpacing.s4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}

// ── Hot-selling header ────────────────────────────────────────────────────────

class _HotSellingHeader extends StatelessWidget {
  const _HotSellingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mediumBackground,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s8,
        ),
        child: Row(
          children: [
            const Icon(KeetaIcons.rank, size: 18, color: AppColors.finalPrice),
            const SizedBox(width: AppSpacing.s6),
            Text(
              'discovery.hot_selling'.tr(),
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hot-selling product grid ──────────────────────────────────────────────────

/// Two-column grid of [ProductCard]s. `buildWhen` keeps the grid sliver out of
/// the screen-root rebuild — only the per-card qty rows below react to the cart.
class _HotSellingGrid extends StatelessWidget {
  const _HotSellingGrid({required this.shop, required this.products});

  final Shop shop;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateView(
          message: 'discovery.no_flash_deals'.tr(),
          icon: KeetaIcons.flame,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.s12),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.s12,
          crossAxisSpacing: AppSpacing.s12,
          // Tall enough for image + name (2 lines) + price/stepper + badges.
          childAspectRatio: 0.62,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => StaggerEntrance(
          index: i,
          child: _FlashCard(shop: shop, product: products[i]),
        ),
      ),
    );
  }
}

/// A hot-selling flash card: a [ProductCard] (big price + discount flag) wrapped
/// in a white tile, with a kcal/time badge strip and a narrow cart-bound rebuild.
class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.shop, required this.product});

  final Shop shop;
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSize.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only this stepper-bearing card rebuilds on cart changes.
          BlocBuilder<CartCubit, CartState>(
            buildWhen: (a, b) =>
                a.qtyOfProduct(product.id) != b.qtyOfProduct(product.id),
            builder: (context, cart) {
              final cubit = context.read<CartCubit>();
              return ProductCard(
                product: product,
                qty: cart.qtyOfProduct(product.id),
                width: double.infinity,
                onAdd: () => quickAddToCart(context, product: product),
                onRemove: () => cubit.removeProduct(product.id),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.shop,
                  arguments: shop.id,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s6),
          _MetaBadges(product: product),
        ],
      ),
    );
  }
}

/// kcal + sold-count badges shown under each flash card.
class _MetaBadges extends StatelessWidget {
  const _MetaBadges({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (product.kcal > 0) ...[
          const Icon(KeetaIcons.flame, size: 12, color: AppColors.tertiaryText),
          const SizedBox(width: AppSpacing.s2),
          Text(
            'discovery.kcal_value'.tr(namedArgs: {'kcal': '${product.kcal}'}),
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
        Expanded(
          child: Text(
            Formatters.sold(product.soldCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sticky cart bar (mirrors shop_screen) ─────────────────────────────────────

class _CartBar extends StatelessWidget {
  const _CartBar({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (a, b) =>
          a.totalQty != b.totalQty ||
          a.subtotal != b.subtotal ||
          a.shopId != b.shopId,
      builder: (context, cart) {
        final active = !cart.isEmpty && cart.shopId == shop.id;
        return SafeArea(
          child: AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: AppMotion.standard,
            margin: const EdgeInsets.all(AppSpacing.s12),
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s16,
              top: AppSpacing.s6,
              bottom: AppSpacing.s6,
              end: AppSpacing.s6,
            ),
            decoration: BoxDecoration(
              color: active ? AppColors.black : AppColors.disabledText,
              borderRadius: BorderRadius.circular(AppRadius.r1),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      KeetaIcons.cart,
                      color: AppColors.white,
                      size: 26,
                    ),
                    if (active)
                      PositionedDirectional(
                        end: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.s4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.totalQty}',
                            style: AppTextStyles.captionSmall.copyWith(
                              color: AppColors.black,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    active
                        ? Formatters.price(cart.subtotal)
                        : 'discovery.add_flash_deals_to_start'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: active
                      ? () => Navigator.pushNamed(
                          context,
                          Routes.checkout,
                          arguments: shop.id,
                        )
                      : null,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s20,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.r1),
                    ),
                    child: Text(
                      'discovery.checkout'.tr(),
                      style: AppTextStyles.headingSmall.copyWith(
                        color: active
                            ? AppColors.black
                            : AppColors.tertiaryText,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
