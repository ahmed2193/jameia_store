import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/order_address.dart';
import 'tracking_card.dart';

class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({super.key, required this.address});
  final OrderAddressEntity address;

  @override
  Widget build(BuildContext context) {
    // Jameia address card title: Medium 14dp (subheadingMedium).
    // Address text: Regular 12dp secondaryText.
    // Recipient+phone: Regular 12dp tertiaryText.
    return TrackingCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 2),
            child: Icon(
              JameiaIcons.location,
              size: 20,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'map.delivering_to'.tr(args: [address.label]),
                  style: AppTextStyles.subheadingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  address.fullText,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  '${address.recipient} · ${address.phone}',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.tertiaryText,
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
