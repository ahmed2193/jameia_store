import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';

/// What changed while the order was picked: unavailable lines and
/// substitutions. Hidden when nothing changed.
class TrackingPickingNotice extends StatelessWidget {
  const TrackingPickingNotice({super.key, required this.picking});

  final OrderPickingEntity picking;

  @override
  Widget build(BuildContext context) {
    if (!picking.hasChanges) return const SizedBox.shrink();
    final lc = context.locale.languageCode;
    return Container(
      color: AppColors.warnBg,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'orders.picking_changes'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.medium,
            ),
          ),
          if (picking.unavailableLineKeys.isNotEmpty)
            Text(
              'orders.unavailable_items'.tr(
                namedArgs: {'count': '${picking.unavailableLineKeys.length}'},
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warn),
            ),
          for (final row in picking.substitutions)
            Text(
              'orders.substituted_item'.tr(
                namedArgs: {'name': row.productNameFor(lc)},
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
