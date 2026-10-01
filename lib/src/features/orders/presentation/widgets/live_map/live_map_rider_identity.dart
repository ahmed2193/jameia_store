import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/courier_trip.dart';
import 'live_map_rider_avatar.dart';

/// Who the rider is: the avatar, their name (or "Your Hero rider" when the
/// feed gives none), their role and vehicle — read out as one node.
class LiveMapRiderIdentity extends StatelessWidget {
  const LiveMapRiderIdentity({super.key, required this.trip});

  final CourierTrip trip;

  @override
  Widget build(BuildContext context) {
    final vehicle = trip.vehicle.labelKey;
    final role = 'orders.person_driver'.tr();
    return MergeSemantics(
      child: Row(
        children: [
          const LiveMapRiderAvatar(),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.riderName.isEmpty
                      ? 'orders.live_rider_default'.tr()
                      : trip.riderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.itemTitleStrong,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  vehicle == null
                      ? role
                      : 'orders.live_role_vehicle'.tr(
                          namedArgs: {'role': role, 'vehicle': vehicle.tr()},
                        ),
                  style: AppTextStyles.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
