import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/deferred_value.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/order_eta.dart';
import '../../../domain/entities/order_journey.dart';
import 'tracking_eta_block.dart';
import 'tracking_journey_text.dart';
import 'tracking_last_known_note.dart';
import 'tracking_late_note.dart';
import 'tracking_stage_art.dart';
import 'tracking_stage_bar.dart';

/// The status panel's content, the way delivery apps lay it out: the time
/// first (or, when there is no time to give, the stage headline in its
/// place) beside the stage disc; the four-stage bar; the stage headline and
/// its line; then a "running late" plate and the "last known status" pill
/// when they apply.
///
/// A change moves in order, never all on one frame (backlog B2-03): the
/// headline and the disc answer at once, the bar follows a short beat later,
/// the optional plates open or fold on their own.
class TrackingHeroContent extends StatelessWidget {
  const TrackingHeroContent({
    super.key,
    required this.order,
    required this.journey,
    required this.eta,
  });

  final OrderEntity order;
  final OrderJourney journey;
  final OrderEta eta;

  @override
  Widget build(BuildContext context) {
    final showsEta = TrackingEtaBlock.shows(eta);
    final lateAt = eta.isLate ? eta.at : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: FadeThroughSwitcher(
                stateKey: showsEta,
                alignment: AlignmentDirectional.centerStart,
                child: showsEta
                    ? TrackingEtaBlock(order: order, eta: eta)
                    : TrackingJourneyText(
                        order: order,
                        journey: journey,
                        prominent: true,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            TrackingStageArt(journey: journey),
          ],
        ),
        DeferredValue<OrderJourney>(
          value: journey,
          delay: AppMotion.fast,
          builder: (context, shown) => CollapseReveal(
            visible: shown.isOnJourney,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.s16),
              child: TrackingStageBar(journey: shown),
            ),
          ),
        ),
        CollapseReveal(
          visible: showsEta,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s16),
            child: TrackingJourneyText(order: order, journey: journey),
          ),
        ),
        CollapseReveal(
          visible: lateAt != null,
          child: lateAt == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: AppSpacing.s12,
                  ),
                  child: TrackingLateNote(
                    expectedAt: lateAt,
                    pickup: order.isPickup,
                  ),
                ),
        ),
        TrackingLastKnownNote(order: order),
      ],
    );
  }
}
