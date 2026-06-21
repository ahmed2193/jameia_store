import 'package:flutter/material.dart';
import '../data/models/shop.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'keeta_image.dart';

/// Horizontal KeeTa shop card for the home feed / channel lists: cover photo with
/// promo ribbon, name, rating, delivery time + fee, distance.
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, this.onTap});

  final Shop shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin, vertical: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                KeetaCardImage(
                    url: shop.cover, height: 150, width: double.infinity),
                if (shop.promo.isNotEmpty)
                  PositionedDirectional(
                    start: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: shop.freeDelivery
                            ? AppColors.freeDelivery
                            : AppColors.finalPrice,
                        borderRadius: BorderRadius.circular(AppRadius.r6),
                      ),
                      child: Text(shop.promo,
                          style: AppTextStyles.captionMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.bold)),
                    ),
                  ),
                if (shop.sponsored)
                  const PositionedDirectional(
                    start: 8,
                    top: 8,
                    child: TagChip(
                        label: 'Ad',
                        bg: AppColors.overlayPrimary,
                        fg: AppColors.white),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                Expanded(
                  child: Text(shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium
                          .copyWith(fontWeight: AppTextStyles.bold)),
                ),
                RatingBadge(rating: shop.rating, count: shop.ratingCount),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.secondaryText),
                const SizedBox(width: 3),
                Text(shop.deliveryTime,
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.secondaryText)),
                const SizedBox(width: AppSpacing.s8),
                Icon(Icons.delivery_dining_rounded,
                    size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 3),
                Text(
                    shop.freeDelivery
                        ? 'Free'
                        : Formatters.price(shop.deliveryFee),
                    style: AppTextStyles.captionLarge.copyWith(
                        color: shop.freeDelivery
                            ? AppColors.freeDelivery
                            : AppColors.secondaryText)),
                const SizedBox(width: AppSpacing.s8),
                Text('· ${Formatters.distance(shop.distanceKm)}',
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.tertiaryText)),
              ],
            ),
            if (shop.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(shop.tags.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText)),
            ],
          ],
        ),
      ),
    );
  }
}
