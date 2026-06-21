import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

/// KeeTa shop / menu screen (`shop_global`) — collapsing cover hero, shop meta,
/// menu sections of [ProductRow]s, and a sticky cart bar driving checkout.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    final shop = sl<KeetaRepository>().shopById(shopId);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          _ShopHero(shop: shop),
          SliverToBoxAdapter(child: _ShopMeta(shop: shop)),
          for (final section in shop.sections) ...[
            SliverToBoxAdapter(
              child: SectionHeader(title: section.title, onSeeAll: null),
            ),
            _MenuSectionSliver(shop: shop, products: section.products),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      bottomNavigationBar: _CartBar(shop: shop),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.white,
      leading: const _CircleIcon(icon: Icons.arrow_back_rounded),
      actions: const [
        _CircleIcon(icon: Icons.favorite_border_rounded),
        _CircleIcon(icon: Icons.more_horiz_rounded),
        SizedBox(width: AppSpacing.s8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            KeetaImage(url: shop.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.overlayPrimary, Colors.transparent],
                ),
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
        onTap: () =>
            icon == Icons.arrow_back_rounded ? Navigator.maybePop(context) : null,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.overlayPrimary,
          child: Icon(icon, size: 18, color: AppColors.white),
        ),
      ),
    );
  }
}

class _ShopMeta extends StatelessWidget {
  const _ShopMeta({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shop.name,
              style: AppTextStyles.displaySmall
                  .copyWith(fontWeight: AppTextStyles.bold)),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              RatingBadge(rating: shop.rating, count: shop.ratingCount),
              const SizedBox(width: AppSpacing.s12),
              Text(shop.tags.join(' · '),
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText)),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s10),
            decoration: BoxDecoration(
              color: AppColors.mediumBackground,
              borderRadius: BorderRadius.circular(AppRadius.r4),
            ),
            child: Row(
              children: [
                Icon(Icons.delivery_dining_rounded,
                    size: 16, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                    shop.freeDelivery
                        ? 'Free delivery'
                        : '${Formatters.price(shop.deliveryFee)} delivery',
                    style: AppTextStyles.captionLarge.copyWith(
                        color: shop.freeDelivery
                            ? AppColors.freeDelivery
                            : AppColors.secondaryText)),
                const SizedBox(width: AppSpacing.s12),
                Icon(Icons.access_time_rounded,
                    size: 15, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(shop.deliveryTime,
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.secondaryText)),
                const Spacer(),
                Text('Min ${Formatters.price(shop.minOrder)}',
                    style: AppTextStyles.captionSmall
                        .copyWith(color: AppColors.tertiaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSectionSliver extends StatelessWidget {
  const _MenuSectionSliver({required this.shop, required this.products});
  final Shop shop;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        final cubit = context.read<CartCubit>();
        return SliverList.separated(
          itemCount: products.length,
          separatorBuilder: (_, _) =>
              const ThinDivider(indent: AppSpacing.s12),
          itemBuilder: (_, i) {
            final p = products[i];
            return ProductRow(
              product: p,
              qty: cart.qtyOf(p.id),
              onAdd: () => cubit.add(p, shop.id),
              onRemove: () => cubit.remove(p.id),
            );
          },
        );
      },
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        final active = !cart.isEmpty && cart.shopId == shop.id;
        return SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(AppSpacing.s12),
            padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.s16, top: 6, bottom: 6, end: 6),
            decoration: BoxDecoration(
              color: active ? AppColors.black : AppColors.disabledText,
              borderRadius: BorderRadius.circular(AppRadius.r1),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_rounded,
                        color: AppColors.white, size: 26),
                    if (active)
                      PositionedDirectional(
                        end: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: Text('${cart.totalQty}',
                              style: AppTextStyles.captionSmall.copyWith(
                                  color: AppColors.black,
                                  fontWeight: AppTextStyles.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    active
                        ? Formatters.price(cart.subtotal)
                        : 'Min ${Formatters.price(shop.minOrder)}',
                    style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: AppTextStyles.bold),
                  ),
                ),
                GestureDetector(
                  onTap: active
                      ? () => Navigator.pushNamed(context, Routes.checkout,
                          arguments: shop.id)
                      : null,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.r1),
                    ),
                    child: Text('Checkout',
                        style: AppTextStyles.headingSmall.copyWith(
                            color: active
                                ? AppColors.black
                                : AppColors.tertiaryText,
                            fontWeight: AppTextStyles.bold)),
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
