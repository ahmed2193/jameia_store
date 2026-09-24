import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';

/// Where the order goes: the frozen delivery address, or the pickup branch.
class TrackingDestinationCard extends StatelessWidget {
  const TrackingDestinationCard({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final address = order.address;
    final String title;
    final String body;
    if (order.isPickup || address == null) {
      title = 'orders.pick_up_from'.tr();
      body = order.branch?.nameFor(lc) ?? '';
    } else {
      title = 'orders.deliver_to'.tr();
      body = [
        if (address.label.isNotEmpty) address.label,
        if (address.summary.isNotEmpty) address.summary,
        // Isolated, or RTL bidi drops the '+' of +965… at the far end
        // of the line and the number reads back to front.
        if (address.phone.isNotEmpty) Formatters.isolate(address.phone),
      ].join('\n');
    }
    if (body.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            order.isPickup ? JameiaIcons.store : JameiaIcons.locationOutline,
            size: AppSize.s22,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryText,
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
