import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_progress_entities.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import 'tracking_info_row.dart';

/// Driver / picker names once assigned and the last failed attempt, one icon
/// row each on a hairline card. Opens (height + fade) when the first of them
/// arrives with a poll; takes no space while there is nothing to say.
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
    final rows = <(IconData, String, Color)>[
      if (pickerName.isNotEmpty)
        (
          Icons.shopping_basket_outlined,
          'orders.picker'.tr(namedArgs: {'name': pickerName}),
          AppColors.primaryText,
        ),
      if (delivery != null && delivery.driverName.isNotEmpty)
        (
          Icons.delivery_dining_outlined,
          'orders.driver'.tr(namedArgs: {'name': delivery.driverName}),
          AppColors.primaryText,
        ),
      if (delivery != null && delivery.hasFailure)
        (
          Icons.error_outline_rounded,
          'orders.delivery_failed_reason'.tr(
            namedArgs: {'reason': delivery.lastFailureReason.labelKey.tr()},
          ),
          AppColors.error,
        ),
    ];
    return CollapseReveal(
      visible: rows.isNotEmpty,
      child: rows.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.s12,
                AppSpacing.gutter,
                0,
              ),
              child: HeroSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.s12),
                      TrackingInfoRow(
                        icon: rows[i].$1,
                        lines: [rows[i].$2],
                        iconColor: rows[i].$3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
