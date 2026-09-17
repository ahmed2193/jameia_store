import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/shop_entity.dart';
import '../util/shop_display.dart';
import 'home_section_header.dart';

/// Jameia home shop-banner rail (`home_page_header_shop_banner_v3`): a horizontal
/// strip of promoted-shop cards — 230×141 cover with a 55dp logo badge bottom-
/// start (`b8c43a`) and a promo bubble top-end (`f5bdcf`, `#1a160c7f` r14),
/// then name / rating / delivery beneath.
class ShopBannerRail extends StatelessWidget {
  const ShopBannerRail({
    super.key,
    required this.title,
    required this.shops,
    required this.onOpenShop,
    this.onSeeAll,
  });

  final String title;
  final List<ShopEntity> shops;
  final void Function(String shopId) onOpenShop;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: title, onSeeAll: onSeeAll),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            itemCount: shops.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (_, i) =>
                _RailCard(shop: shops[i], onTap: () => onOpenShop(shops[i].id)),
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.shop, this.onTap});
  final ShopEntity shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tag = shop.displayTags.isNotEmpty ? shop.displayTags.first : null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 230×141 cover with logo badge + promo bubble.
            SizedBox(
              width: 230,
              height: 141,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    JameiaImage(
                      url: shop.cover,
                      width: 230,
                      height: 141,
                      fit: BoxFit.cover,
                    ),
                    if (tag != null)
                      PositionedDirectional(
                        top: 12,
                        end: 12,
                        child: Container(
                          height: 24,
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.bannerTagBg,
                            borderRadius: BorderRadius.circular(AppSize.r14),
                          ),
                          child: Text(
                            tag.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppSize.font12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      bottom: 8,
                      start: 8,
                      child: Container(
                        // logo badge b8c43a: 55dp white square r8 (kept ~50 to
                        // fit the 141dp card proportions).
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppSize.r8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSize.r6),
                          // 50dp badge − 2dp padding each side → ~46dp logo.
                          child: JameiaImage(
                            url: shop.logo,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              shop.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.medium,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                RatingBadge(rating: shop.rating, count: shop.ratingCount),
                const DotSep(),
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
                Text(
                  shop.freeDelivery
                      ? 'home.free'.tr()
                      : Formatters.price(shop.deliveryFee),
                  style: TextStyle(
                    fontSize: AppSize.font12,
                    color: shop.freeDelivery
                        ? AppColors.freeDelivery
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
