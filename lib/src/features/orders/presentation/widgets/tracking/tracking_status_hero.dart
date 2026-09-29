import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/order_eta.dart';
import '../../../domain/entities/order_journey.dart';
import 'tracking_delivered_moment.dart';
import 'tracking_hero_content.dart';
import 'tracking_minute_builder.dart';

/// The top of the order page: a washed panel, rounded at its foot, that
/// holds where the order stands and when it comes (see
/// [TrackingHeroContent]). The time is recomputed on the page's minute
/// clock, so a countdown moves on its own while the customer watches; the
/// delivered moment plays over the panel when a live update lands.
class TrackingStatusHero extends StatelessWidget {
  const TrackingStatusHero({super.key, required this.order});

  final OrderEntity order;

  static const BorderRadius _shape = BorderRadius.vertical(
    bottom: Radius.circular(AppRadius.r2),
  );

  /// The panel's wash follows the journey: brand while it moves or is done,
  /// warm when the delivery failed, grey once cancelled.
  static Color _wash(OrderJourneyTone tone) => switch (tone) {
    OrderJourneyTone.active || OrderJourneyTone.done => AppColors.brandWash,
    OrderJourneyTone.attention => AppColors.warnBg,
    OrderJourneyTone.stopped => AppColors.smallBackground,
  };

  @override
  Widget build(BuildContext context) {
    final journey = OrderJourney.of(order);
    return TrackingDeliveredMoment(
      status: order.status,
      // A poll that stops the order eases the wash over.
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: AppMotion.signature,
        decoration: BoxDecoration(
          color: _wash(journey.tone),
          borderRadius: _shape,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s16,
            AppSpacing.gutter,
            AppSpacing.s20,
          ),
          child: TrackingMinuteBuilder(
            builder: (context, now) => TrackingHeroContent(
              order: order,
              journey: journey,
              eta: OrderEta.of(order, now),
            ),
          ),
        ),
      ),
    );
  }
}
