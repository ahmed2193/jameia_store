import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';

/// Who cancelled and the note they left.
class TrackingCancellationNotice extends StatelessWidget {
  const TrackingCancellationNotice({super.key, required this.cancellation});

  final OrderCancellationEntity cancellation;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.errorBg,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cancellation.byCustomer
                ? 'orders.cancelled_by_you'.tr()
                : 'orders.cancelled_by_store'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.error,
              fontWeight: AppTextStyles.medium,
            ),
          ),
          if (cancellation.note.isNotEmpty)
            Text(
              'orders.cancellation_note'.tr(
                namedArgs: {'note': cancellation.note},
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
        ],
      ),
    );
  }
}
