import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../util/product_display.dart';
import '../util/shop_display.dart';

/// Jameia `c_search_shop` result card — a shop header (logo · name · rating ·
/// delivery/time/distance · promo tags) above a horizontal rail of that shop's
/// products (image + optional "% off" badge · price · after-voucher · struck
/// original · name), then a centered "See all N items ›". A hairline divider
/// closes the card. Pickup mode swaps the delivery line for "Ready in …".
class ShopResultCard extends StatelessWidget {
  const ShopResultCard({
    super.key,
    required this.shop,
    required this.pickup,
    required this.onOpenShop,
    required this.onOpenProduct,
  });

  final ShopEntity shop;
  final bool pickup;
  final void Function(String shopId) onOpenShop;
  final void Function(ProductEntity product) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final products = shop.products;
    final promoCount = products.where((p) => p.hasDiscount).length;
    final rail = products.take(10).toList(growable: false);
    // Rail height = fixed 110dp image + gaps + the (text-scaled) text block, so
    // discounted cards (price + after-voucher + struck original + 2-line name)
    // never overflow when the OS font size is enlarged (clamped to 1.3x).
    final railHeight = 120 + MediaQuery.textScalerOf(context).scale(84);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        PressScale(
          child: InkWell(
            onTap: () => onOpenShop(shop.id),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                12,
                12,
                12,
                AppSpacing.s8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                    child: JameiaImage(
                      url: shop.logo,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NameRow(name: shop.displayName, pickup: pickup),
                        const SizedBox(height: 3),
                        RatingBadge(
                          rating: shop.rating,
                          count: shop.ratingCount,
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(shop: shop, pickup: pickup),
                        const SizedBox(height: AppSpacing.s6),
                        _Tags(
                          freeDelivery: shop.freeDelivery,
                          promoCount: promoCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Product rail ──────────────────────────────────────────────────
        if (rail.isNotEmpty)
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              itemCount: rail.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
              itemBuilder: (_, i) => _RailProduct(
                product: rail[i],
                onTap: () => onOpenProduct(rail[i]),
              ),
            ),
          ),
        // ── See all ───────────────────────────────────────────────────────
        if (products.isNotEmpty)
          GestureDetector(
            onTap: () => onOpenShop(shop.id),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'search.see_all_items'.tr(
                      namedArgs: {'count': '${products.length}'},
                    ),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const Icon(
                    JameiaIcons.arrowRightSmall,
                    size: 14,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        Container(
          height: 0.5,
          margin: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          color: AppColors.primaryText.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name, required this.pickup});
  final String name;
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    if (!pickup) {
      return Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      );
    }
    return Row(
      children: [
        Text(
          '${'search.pickup'.tr().toUpperCase()} · ',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.freeDelivery,
            fontWeight: AppTextStyles.bold,
          ),
        ),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.shop, required this.pickup});
  final ShopEntity shop;
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    const grey = TextStyle(
      fontSize: AppSize.font12,
      color: AppColors.labelGrey,
    );
    if (pickup) {
      return Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 12,
            color: AppColors.labelGrey,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              'search.ready_in'.tr(namedArgs: {'time': shop.deliveryTime}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: grey,
            ),
          ),
          const DotSep(),
          Text(
            Formatters.distance(shop.distanceKm),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: grey,
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(
          Icons.delivery_dining_rounded,
          size: 13,
          color: AppColors.labelGrey,
        ),
        const SizedBox(width: 3),
        Text(
          shop.freeDelivery
              ? 'core.free'.tr()
              : Formatters.price(shop.deliveryFee),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppSize.font12,
            color: shop.freeDelivery
                ? AppColors.freeDelivery
                : AppColors.labelGrey,
            fontWeight: shop.freeDelivery
                ? AppTextStyles.medium
                : AppTextStyles.regular,
          ),
        ),
        const DotSep(),
        Flexible(
          child: Text(
            shop.deliveryTime,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: grey,
          ),
        ),
        const DotSep(),
        Flexible(
          child: Text(
            Formatters.distance(shop.distanceKm),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: grey,
          ),
        ),
      ],
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.freeDelivery, required this.promoCount});
  final bool freeDelivery;
  final int promoCount;

  @override
  Widget build(BuildContext context) {
    final tags = <Widget>[
      if (promoCount > 0)
        _Tag(
          label: 'search.promo_items'.tr(namedArgs: {'count': '$promoCount'}),
          bg: AppColors.promotionTagBg, // #FFE41F
          fg: AppColors.primaryText,
        ),
      if (freeDelivery)
        _Tag(
          label: 'search.free_delivery'.tr(),
          bg: AppColors.freeDeliveryBg,
          fg: AppColors.freeDelivery,
        ),
    ];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.s6,
      runSpacing: AppSpacing.s4,
      children: tags,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionSmall.copyWith(
          color: fg,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

// ── Rail product card (tap → open shop; no cart control per Jameia) ────────────
class _RailProduct extends StatelessWidget {
  const _RailProduct({required this.product, required this.onTap});
  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discounted = product.hasDiscount;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                JameiaImage(
                  url: product.image,
                  width: 110,
                  height: 110,
                  radius: AppRadius.r6,
                ),
                if (product.discountPercent > 0)
                  PositionedDirectional(
                    start: 0,
                    bottom: 8,
                    child: Container(
                      height: 22,
                      padding: const EdgeInsetsDirectional.only(
                        start: 6,
                        end: 8,
                      ),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.promotionTagBg, // yellow #FFE41F
                        borderRadius: BorderRadiusDirectional.only(
                          topEnd: Radius.circular(AppSize.r11),
                          bottomEnd: Radius.circular(AppSize.r11),
                        ),
                      ),
                      child: Text(
                        'search.percent_off'.tr(
                          namedArgs: {'percent': '${product.discountPercent}'},
                        ),
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              Formatters.price(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.bold,
              ),
            ),
            if (discounted) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                'search.after_voucher'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.freeDelivery,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
              Text(
                Formatters.price(product.originalPrice),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.secondaryText,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s2),
            Text(
              product.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.primaryText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
