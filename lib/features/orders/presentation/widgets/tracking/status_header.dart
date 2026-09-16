import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/keeta_image.dart';
import '../../../domain/entities/order.dart';
import '../../util/order_display.dart';
import 'tracking_card.dart';

String _statusHeadline(int step) {
  return switch (step) {
    1 => 'orders.headline_confirmed'.tr(),
    2 => 'orders.headline_preparing'.tr(),
    3 => 'orders.headline_picked_up'.tr(),
    4 => 'orders.headline_on_the_way'.tr(),
    _ => 'orders.headline_delivered'.tr(),
  };
}

class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key, required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    // Real KeeTa (b31eae): headline Medium 18dp primaryText.
    // Real KeeTa (ddaf19): sub-label Regular 12dp #4d4d4d ≈ secondaryText.
    // Shop avatar (acf275): 40×40dp, radius=13dp, border=1.5dp white.
    return TrackingCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.circular(AppSize.r13), // acf275: radius=13dp
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: KeetaImage(url: order.shopLogo, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusHeadline(order.statusStep),
                  // b31eae: Medium 18dp
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.displayShopName} · #${order.id.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // ddaf19: Regular 12dp #4d4d4d
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
