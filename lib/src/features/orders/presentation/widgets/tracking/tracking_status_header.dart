import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../config/theme/order_status_palette.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/utils/formatters.dart';
import 'tracking_progress_stepper.dart';

/// Status name, when to expect the order (ETA or booked window), the order
/// number and date, and the progress stepper.
class TrackingStatusHeader extends StatelessWidget {
  const TrackingStatusHeader({super.key, required this.order});

  final OrderEntity order;

  String? _when(String languageCode) {
    final slot = order.deliverySlot;
    if (slot != null) {
      final day = slot.day;
      return 'orders.slot_window'.tr(
        namedArgs: {
          // The wire day is `2026-09-22`; write it the way the customer reads
          // dates, and isolate the clock times so an Arabic line keeps them
          // as `10:00 – 12:00` instead of reordering the digits.
          'date': day == null ? slot.date : Formatters.date(languageCode, day),
          'start': Formatters.isolate(slot.start),
          'end': Formatters.isolate(slot.end),
        },
      );
    }
    final eta = order.etaMinutes;
    if (eta != null && eta > 0 && !order.isTerminal) {
      // Nothing arrives for a pickup order — the customer is the one travelling.
      return (order.isPickup
              ? 'orders.eta_pickup_minutes'
              : 'orders.eta_minutes')
          .tr(namedArgs: {'minutes': '$eta'});
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final when = _when(context.locale.languageCode);
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            order.status.labelKey.tr(),
            style: AppTextStyles.headingLarge.copyWith(
              color: OrderStatusPalette.foreground(order.status),
              fontWeight: AppTextStyles.bold,
            ),
          ),
          if (when != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              when,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${'orders.order_no'.tr(namedArgs: {'number': Formatters.isolate(order.orderNumber)})}'
            ' · ${Formatters.dateTime(context.locale.languageCode, order.createdAt)}',
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          if (order.progressStep != null) ...[
            const SizedBox(height: AppSpacing.s16),
            TrackingProgressStepper(step: order.progressStep!),
          ],
        ],
      ),
    );
  }
}
