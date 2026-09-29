import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../config/theme/order_status_palette.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../domain/entities/order_journey.dart';

/// Where the order is, in words: the stage headline ("Packing your order")
/// and the line under it ("Ahmed is picking your items", "Pick it up from
/// Salmiya", "Last attempt: nobody was home"). [prominent] when it leads the
/// panel (no time to show): the headline takes the big title size.
///
/// The pair fades through when the headline changes (a new stage), never on
/// a poll that keeps it. Announced once per change: the live region reads
/// the headline, the switcher itself is excluded.
class TrackingJourneyText extends StatelessWidget {
  const TrackingJourneyText({
    super.key,
    required this.order,
    required this.journey,
    this.prominent = false,
  });

  final OrderEntity order;
  final OrderJourney journey;
  final bool prominent;

  String _detail(String languageCode) {
    final reasonKey = journey.detailReasonKey;
    return journey.detailKey.tr(
      namedArgs: {
        'name': journey.pickup && journey.detailName.isEmpty
            ? order.branch?.nameFor(languageCode) ?? ''
            : journey.detailName,
        if (reasonKey.isNotEmpty) 'reason': reasonKey.tr(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final headline = journey.headlineKey.tr();
    final detail = _detail(context.locale.languageCode);
    final style = prominent
        ? AppTextStyles.sectionTitle
        : AppTextStyles.groupTitle;
    return Semantics(
      liveRegion: true,
      header: true,
      label: '$headline. $detail',
      child: ExcludeSemantics(
        child: FadeThroughSwitcher(
          stateKey: journey.headlineKey,
          alignment: AlignmentDirectional.topStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                style: style.copyWith(
                  color: OrderStatusPalette.headline(order.status),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(detail, style: AppTextStyles.meta),
            ],
          ),
        ),
      ),
    );
  }
}
