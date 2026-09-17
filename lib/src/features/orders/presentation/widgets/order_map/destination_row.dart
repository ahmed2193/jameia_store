import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/order_address.dart';

/// Fallback row when the order has no rider yet — shows where it's heading.
class DestinationRow extends StatelessWidget {
  const DestinationRow({super.key, required this.address});
  final OrderAddressEntity address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          JameiaIcons.location,
          size: 20,
          color: AppColors.primaryText,
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'map.delivering_to'.tr(args: [address.label]),
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address.fullText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
