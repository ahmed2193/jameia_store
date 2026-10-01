import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/courier_trip.dart';
import 'live_map_alerts_prompt.dart';
import 'live_map_eta.dart';
import 'live_map_rider_card.dart';
import 'live_map_route_credit.dart';
import 'live_map_track.dart';

/// The white card over the foot of the live map, the way delivery apps
/// keep the facts under the map: the time to the door and where the ride
/// stands ([LiveMapEta]), the store → door track ([LiveMapTrack]) and who
/// brings the order ([LiveMapRiderCard]). Each part rebuilds on its own
/// slice of the state; the card never rebuilds per frame.
class LiveMapPanel extends StatelessWidget {
  const LiveMapPanel({super.key, required this.trip});

  final CourierTrip trip;

  static const BorderRadius _shape = BorderRadius.vertical(
    top: Radius.circular(AppRadius.sheet),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: _shape,
        boxShadow: AppShadows.high,
      ),
      child: SafeArea(
        top: false,
        // A keyboard over the page (the chat sheet's) never shortens the
        // panel, so the map padding and its framing hold still.
        maintainBottomViewPadding: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s20,
            AppSpacing.gutter,
            AppSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const LiveMapAlertsPrompt(),
              const LiveMapEta(),
              const SizedBox(height: AppSpacing.s16),
              const LiveMapTrack(),
              LiveMapRiderCard(trip: trip),
              LiveMapRouteCredit(source: trip.routeSource),
            ],
          ),
        ),
      ),
    );
  }
}
