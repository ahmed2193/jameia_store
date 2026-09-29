import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';

/// One step of "Order updates": a dot on the rail, the status name and when
/// it happened. Every step here has happened, so the rail and the dots are
/// in the brand green (grey is the stage bar's "still to come"); the latest
/// dot is filled — red when the order was cancelled or its delivery failed. The rail runs down to the
/// next step unless this is the [last] one — a positioned line beside the
/// text, so the row sizes to its text in one layout pass. Read out as one
/// node.
class TrackingTimelineRow extends StatelessWidget {
  const TrackingTimelineRow({
    super.key,
    required this.event,
    required this.latest,
    required this.last,
  });

  final OrderStatusEvent event;
  final bool latest;
  final bool last;

  static const double _dot = AppSize.s12;
  static const double _rail = AppSize.s2;
  static const double _railColumn = AppSize.s24;

  /// The dot sits level with the first text line.
  static const double _dotTop = AppSpacing.s4;

  @override
  Widget build(BuildContext context) {
    final lc = context.locale.languageCode;
    final stopped =
        event.status == OrderStatus.cancelled ||
        event.status == OrderStatus.deliveryFailed;
    final ink = latest && stopped ? AppColors.error : AppColors.primary;
    final local = event.at.toLocal();
    final time = DateUtils.isSameDay(local, DateTime.now())
        ? Formatters.clock(lc, local)
        : Formatters.dateTime(lc, local);
    return MergeSemantics(
      child: Stack(
        children: [
          if (!last)
            const PositionedDirectional(
              start: (_railColumn - _rail) / 2,
              top: _dotTop + _dot,
              bottom: 0,
              width: _rail,
              child: ColoredBox(color: AppColors.primary),
            ),
          PositionedDirectional(
            start: (_railColumn - _dot) / 2,
            top: _dotTop,
            child: SizedBox.square(
              dimension: _dot,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: latest ? ink : AppColors.white,
                  border: Border.all(color: ink, width: _rail),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: _railColumn + AppSpacing.s8,
              bottom: last ? 0 : AppSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.status.labelKey.tr(),
                  style: latest
                      ? AppTextStyles.itemTitleStrong
                      : AppTextStyles.itemTitle,
                ),
                Text(Formatters.isolate(time), style: AppTextStyles.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
