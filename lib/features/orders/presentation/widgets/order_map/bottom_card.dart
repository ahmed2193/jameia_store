import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/common.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_address.dart';
import 'destination_row.dart';
import 'eta_row.dart';
import 'info_row.dart';
import 'rider_row.dart';
import 'sheet_grabber.dart';

// ── Bottom card (ETA + rider + actions) ──────────────────────────────────────

class BottomCard extends StatelessWidget {
  const BottomCard({
    super.key,
    required this.order,
    required this.address,
    required this.dropOff,
    required this.onTapDropOff,
  });
  final OrderEntity order;
  final OrderAddressEntity address;
  final String dropOff;
  final VoidCallback onTapDropOff;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadius.r3),
          topEnd: Radius.circular(AppRadius.r3),
        ),
        boxShadow: AppShadows.high,
      ),
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.s16,
        end: AppSpacing.s16,
        top: AppSpacing.s12,
        bottom: AppSpacing.s16 + bottomPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetGrabber(),
          const SizedBox(height: AppSpacing.s12),
          EtaRow(order: order),
          const SizedBox(height: AppSpacing.s12),
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          if (order.rider != null)
            RiderRow(rider: order.rider!)
          else
            DestinationRow(address: address),
          const SizedBox(height: AppSpacing.s12),
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          // Drop-off preference (i18n `HAND_TO_ME` / `LEAVE_AT_DESIGNATED_SPOT`)
          // — tappable, opens a toggle sheet.
          InfoRow(
            icon: KeetaIcons.address,
            label: 'dropoff.title'.tr(),
            value: _dropOffLabel(dropOff),
            onTap: onTapDropOff,
          ),
          const SizedBox(height: AppSpacing.s10),
          // Platform fee (i18n `order_pickup_platform_fee`).
          InfoRow(
            icon: KeetaIcons.pay,
            label: 'map.platform_fee'.tr(),
            value: Formatters.price(order.platformFee),
          ),
        ],
      ),
    );
  }
}

String _dropOffLabel(String method) => method == 'hand_to_me'
    ? 'dropoff.hand_to_me'.tr()
    : 'dropoff.leave_spot'.tr();
