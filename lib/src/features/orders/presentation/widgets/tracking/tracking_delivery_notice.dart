import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';

/// Driver / picker names once assigned and the last failed attempt.
class TrackingDeliveryNotice extends StatelessWidget {
  const TrackingDeliveryNotice({
    super.key,
    this.delivery,
    this.pickerName = '',
  });

  final OrderDeliveryEntity? delivery;
  final String pickerName;

  @override
  Widget build(BuildContext context) {
    final delivery = this.delivery;
    final lines = <String>[
      if (pickerName.isNotEmpty)
        'orders.picker'.tr(namedArgs: {'name': pickerName}),
      if (delivery != null && delivery.driverName.isNotEmpty)
        'orders.driver'.tr(namedArgs: {'name': delivery.driverName}),
      if (delivery != null && delivery.hasFailure)
        'orders.delivery_failed_reason'.tr(
          namedArgs: {'reason': delivery.lastFailureReason.labelKey.tr()},
        ),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Text(
              line,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
        ],
      ),
    );
  }
}
