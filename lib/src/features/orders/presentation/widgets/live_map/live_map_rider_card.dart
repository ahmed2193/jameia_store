import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/widgets/hero_tag.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../../domain/entities/courier_trip.dart';
import '../../cubit/courier_tracking_cubit.dart';
import 'live_map_contact_actions.dart';
import 'live_map_rider_identity.dart';

/// Who brings the order, once a rider is found ([LiveMapRiderIdentity]):
/// their name, role and vehicle — how they get here says how fast the last
/// stretch can go. On its end, a "Now" tag while
/// they head to the store; once they head to the customer, message and call
/// ([LiveMapContactActions]) take its place. The rider is read out as one
/// node, each action on its own.
class LiveMapRiderCard extends StatelessWidget {
  const LiveMapRiderCard({super.key, required this.trip});

  final CourierTrip trip;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<CourierTrackingCubit, CourierStage?>(
      (cubit) => cubit.state.stage,
    );
    final found = stage != null && stage.hasRider;
    final reachable = stage != null && stage.delivering;
    return CollapseReveal(
      visible: found,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.s16),
        child: Row(
          children: [
            Expanded(child: LiveMapRiderIdentity(trip: trip)),
            const SizedBox(width: AppSpacing.s8),
            PopSwitcher(
              stateKey: reachable,
              alignment: AlignmentDirectional.centerEnd,
              child: reachable
                  ? LiveMapContactActions(trip: trip)
                  : found
                  ? HeroTag(label: 'orders.person_now'.tr(), pill: true)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
