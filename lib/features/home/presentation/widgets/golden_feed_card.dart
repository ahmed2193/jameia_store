import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';

/// KeeTa home feed "golden" shop card (`home_page_feeds_card_with_dishes_golden`
/// / `feeds_grocery_card`). White card r12, 10dp padding (`dbd094`/`cd58f9`):
/// 100×100 r16 cover (closed overlay `#22222299` + Ad label), info column
/// (name 16 bold · rating · delivery meta with dot separators · promo ribbons +
/// feature labels), then a dish-thumbnail strip with prices.
class FeedShopCard extends StatelessWidget {
  const FeedShopCard({super.key, required this.shop, this.onTap});

  final Shop shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dishCount = shop.isRestaurant ? 3 : 4;
    final dishes = shop.allProducts.take(dishCount).toList(growable: false);
    final tags = shop.displayTags;
    final features = shop.displayFeatures;

    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.pageMargin,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.overlayDivider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayOnContent,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Cover(shop: shop),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Info(shop: shop, tags: tags, features: features),
                  ),
                ],
              ),
              if (dishes.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DishStrip(dishes: dishes, count: dishCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.r16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            KeetaImage(
              url: shop.cover,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(color: AppColors.overlayOnContent),
            ),
            // Brand logo badge — 30×30 white r5 top-start (XML: start:10 top:10).
            if (shop.logo.isNotEmpty)
              PositionedDirectional(
                start: 8,
                top: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSize.r5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: KeetaImage(
                    url: shop.logo,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (!shop.isOpen)
              Container(
                color: AppColors.closedOverlay,
                alignment: Alignment.center,
                child: Text(
                  shop.notice.isNotEmpty ? shop.notice : 'home.closed'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppSize.font12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            if (shop.sponsored)
              const PositionedDirectional(end: 6, bottom: 6, child: _AdTag()),
          ],
        ),
      ),
    );
  }
}

class _AdTag extends StatelessWidget {
  const _AdTag();
  // XML: "Ad" label, color #E5E5E5, font-size 8, bottom-end, no background box.
  // A subtle shadow keeps it legible over light cover photos.
  @override
  Widget build(BuildContext context) => Text(
    'home.ad'.tr(),
    style: const TextStyle(
      fontSize: AppSize.font8,
      color: AppColors.adTagText,
      shadows: [Shadow(color: AppColors.scrimTop40, blurRadius: 2)],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.shop, required this.tags, required this.features});
  final Shop shop;
  final List<PromoTag> tags;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: AppSize.font16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 5),
        RatingBadge(rating: shop.rating, count: shop.ratingCount),
        const SizedBox(height: 3),
        // Delivery meta: time · fee/free · distance, dot-separated.
        Row(
          children: [
            const Icon(
              KeetaIcons.time,
              size: 12,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                shop.deliveryTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSize.font12,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const DotSep(),
            const Icon(
              KeetaIcons.delivery,
              size: 13,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                shop.freeDelivery
                    ? 'home.free_delivery'.tr()
                    : Formatters.price(shop.deliveryFee),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSize.font12,
                  color: shop.freeDelivery
                      ? AppColors.freeDelivery
                      : AppColors.secondaryText,
                  fontWeight: shop.freeDelivery
                      ? AppTextStyles.medium
                      : AppTextStyles.regular,
                ),
              ),
            ),
            const DotSep(),
            Text(
              Formatters.distance(shop.distanceKm),
              style: const TextStyle(
                fontSize: AppSize.font12,
                color: AppColors.tertiaryText,
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty || features.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final t in tags.take(2)) PromoRibbon(tag: t),
              for (final f in features.take(2)) FeatureLabel(text: f),
            ],
          ),
        ],
      ],
    );
  }
}

class _DishStrip extends StatelessWidget {
  const _DishStrip({required this.dishes, required this.count});
  final List<Product> dishes;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: i < count - 1 ? 8 : 0),
              child: i < dishes.length
                  ? _DishThumb(product: dishes[i])
                  : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}

class _DishThumb extends StatelessWidget {
  const _DishThumb({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dish image with the real 0.5dp #EDEDED hairline border (atom e9f34b).
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.r8),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: KeetaImage(url: product.image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          Formatters.price(product.price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: AppSize.font12,
            fontWeight: FontWeight.w700,
            color: AppColors.finalPrice,
          ),
        ),
      ],
    );
  }
}

/// Themed/promo feed card (`feeds_theme_card`) — full-bleed cover with a dark
/// overlay (`#00000099`) and a centered white title (used for highlighted/
/// sponsored shops in the feed).
class ThemeFeedCard extends StatelessWidget {
  const ThemeFeedCard({super.key, required this.shop, this.onTap});

  final Shop shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tag = shop.displayTags.isNotEmpty ? shop.displayTags.first : null;
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.pageMargin,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              KeetaImage(url: shop.cover, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.scrimSoft20, AppColors.overlayPrimary],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 12,
                end: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag != null) ...[
                      PromoRibbon(tag: tag),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      shop.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppSize.font16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
