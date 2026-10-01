import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/flip_value.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/order_eta.dart';

/// The big time at the top of the status panel, in three lines: what it is
/// ("Arriving in", "Scheduled delivery", "Delivered at"), the value itself
/// ("35 min", "6:00 – 7:00 PM", "8:41 PM") and a footnote ("Estimated at
/// 8:45 PM", the booked day, how long it took).
///
/// Motion: the label fades through only when the KIND of time changes; the
/// value flips (up and out, in from below) when it changes — each minute of
/// a countdown — never on a rebuild that keeps it. Built from [eta] only;
/// the page recomputes [eta] once a minute.
class TrackingEtaBlock extends StatelessWidget {
  const TrackingEtaBlock({super.key, required this.order, required this.eta});

  final OrderEntity order;
  final OrderEta eta;

  /// The kinds that have a big value (late, cancelled and none do not).
  static bool shows(OrderEta eta) => switch (eta.kind) {
    OrderEtaKind.arriving ||
    OrderEtaKind.readyAround ||
    OrderEtaKind.window ||
    OrderEtaKind.delivered => true,
    _ => false,
  };

  (String, String, String) _lines(String languageCode) {
    final at = eta.at;
    final clock = at == null
        ? ''
        : Formatters.isolate(Formatters.clock(languageCode, at));
    switch (eta.kind) {
      case OrderEtaKind.arriving:
      case OrderEtaKind.readyAround:
        return (
          (eta.kind == OrderEtaKind.arriving
                  ? 'orders.eta_arriving_label'
                  : 'orders.eta_ready_label')
              .tr(),
          'orders.eta_minutes_count'.plural(
            eta.minutesLeft ?? 0,
            namedArgs: {'minutes': '${eta.minutesLeft ?? 0}'},
          ),
          'orders.eta_around'.tr(namedArgs: {'time': clock}),
        );
      case OrderEtaKind.window:
        final slot = eta.slot;
        final day = slot?.day;
        return (
          'orders.eta_window_label'.tr(),
          'orders.eta_window_value'.tr(
            namedArgs: {
              'start': Formatters.isolate(slot?.start ?? ''),
              'end': Formatters.isolate(slot?.end ?? ''),
            },
          ),
          day == null ? (slot?.date ?? '') : Formatters.date(languageCode, day),
        );
      case OrderEtaKind.delivered:
        final took = eta.took;
        final date = Formatters.dayMonth(languageCode, at);
        return (
          (order.isPickup
                  ? 'orders.eta_picked_up_label'
                  : 'orders.eta_delivered_label')
              .tr(),
          clock,
          took == null
              ? date
              : 'orders.eta_took'.plural(
                  took.inMinutes,
                  namedArgs: {'date': date, 'minutes': '${took.inMinutes}'},
                ),
        );
      case OrderEtaKind.late:
      case OrderEtaKind.cancelled:
      case OrderEtaKind.none:
        return ('', '', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, value, note) = _lines(context.locale.languageCode);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeThroughSwitcher(
            stateKey: eta.kind,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: AppColors.brandDeep),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          FlipValue(
            flipKey: value,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displayLarge.copyWith(
                fontWeight: AppTextStyles.bold,
                fontFeatures: AppTextStyles.tabular,
              ),
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(note, style: AppTextStyles.meta),
          ],
        ],
      ),
    );
  }
}
