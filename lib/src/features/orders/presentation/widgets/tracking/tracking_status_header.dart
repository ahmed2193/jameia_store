import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../config/theme/order_status_palette.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/utils/formatters.dart';
import 'tracking_progress_stepper.dart';

/// The page's lead: the status name (ink; red when cancelled), when to expect
/// the order (ETA or booked window), the order number and date, and the
/// journey stepper. The headline and the when-line fade through when a poll
/// changes them; the stepper folds away when the order leaves the journey
/// (cancelled). Reads no provider — a pure function of [order].
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
    final languageCode = context.locale.languageCode;
    final when = _when(languageCode);
    final status = order.status.labelKey.tr();
    final step = order.progressStep;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // One announcement per status change: the switcher keeps the
          // outgoing headline's semantics while it fades, so the live region
          // reads the label and the switcher is excluded.
          Semantics(
            header: true,
            liveRegion: true,
            label: status,
            child: ExcludeSemantics(
              child: FadeThroughSwitcher(
                stateKey: order.status,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  status,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: OrderStatusPalette.headline(order.status),
                  ),
                ),
              ),
            ),
          ),
          CollapseReveal(
            visible: when != null,
            child: when == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.s4,
                    ),
                    child: FadeThroughSwitcher(
                      stateKey: when,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(when, style: AppTextStyles.itemTitleStrong),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${'orders.order_no'.tr(namedArgs: {'number': Formatters.isolate(order.orderNumber)})}'
            ' · ${Formatters.dateTime(languageCode, order.createdAt)}',
            style: AppTextStyles.meta,
          ),
          CollapseReveal(
            visible: step != null,
            child: step == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.s16,
                    ),
                    child: TrackingProgressStepper(step: step),
                  ),
          ),
        ],
      ),
    );
  }
}
