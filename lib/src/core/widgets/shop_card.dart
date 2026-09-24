import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../data/models/shop.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'jameia_image.dart';

/// Horizontal Jameia shop card for the home feed / channel lists: cover photo with
/// promo ribbon, name, rating, delivery time + fee, distance.
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, this.onTap});

  final Shop shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin,
            vertical: AppSpacing.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  JameiaCardImage(
                    url: shop.cover,
                    height: AppSize.s150,
                    width: double.infinity,
                  ),
                  if (shop.promo.isNotEmpty)
                    PositionedDirectional(
                      start: AppSize.s8,
                      bottom: AppSize.s8,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s3,
                        ),
                        decoration: BoxDecoration(
                          color: shop.freeDelivery
                              ? AppColors.freeDelivery
                              : AppColors.finalPrice,
                          borderRadius: BorderRadius.circular(AppRadius.r6),
                        ),
                        child: Text(
                          shop.promo,
                          style: AppTextStyles.captionMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                      ),
                    ),
                  if (shop.sponsored)
                    PositionedDirectional(
                      start: AppSize.s8,
                      top: AppSize.s8,
                      child: TagChip(
                        label: 'core.ad'.tr(),
                        bg: AppColors.overlayPrimary,
                        fg: AppColors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shop.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                  RatingBadge(rating: shop.rating, count: shop.ratingCount),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: AppSize.s13,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    shop.deliveryTime,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Icon(
                    Icons.delivery_dining_rounded,
                    size: AppSize.s14,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    shop.freeDelivery
                        ? 'core.free'.tr()
                        : Formatters.price(shop.deliveryFee),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: shop.freeDelivery
                          ? AppColors.freeDelivery
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    '· ${Formatters.distance(shop.distanceKm)}',
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                  ),
                ],
              ),
              if (shop.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(
                  shop.tags.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
