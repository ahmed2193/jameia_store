import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../cubit/address_edit_cubit.dart';
import 'drop_off_tile.dart';
import 'drop_spot_picker.dart';
import 'section_header.dart';

/// Delivery instructions — hand-to-me vs leave-at-spot + drop-spot chips +
/// required alt-location input (RE §3.5).
class DeliveryInstructionsSection extends StatelessWidget {
  const DeliveryInstructionsSection({
    super.key,
    required this.altError,
    required this.onClearAltError,
  });

  final bool altError;
  final VoidCallback onClearAltError;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'dropoff.title'.tr()),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: AppSpacing.s14,
            ),
            child: BlocSelector<AddressEditCubit, AddressEditState, DropOff>(
              selector: (s) => s.dropOff,
              builder: (context, active) {
                final cubit = context.read<AddressEditCubit>();
                return Column(
                  children: [
                    DropOffTile(
                      icon: KeetaIcons.contactRider,
                      title: 'dropoff.hand_to_me'.tr(),
                      subtitle: 'dropoff.hand_to_me_sub'.tr(),
                      selected: active == DropOff.handToMe,
                      onTap: () => cubit.setDropOff(DropOff.handToMe),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    DropOffTile(
                      icon: KeetaIcons.address,
                      title: 'dropoff.leave_spot'.tr(),
                      subtitle: 'dropoff.leave_spot_sub'.tr(),
                      selected: active == DropOff.leaveAtSpot,
                      onTap: () => cubit.setDropOff(DropOff.leaveAtSpot),
                    ),
                    if (active == DropOff.leaveAtSpot) ...[
                      const SizedBox(height: AppSpacing.s12),
                      DropSpotPicker(
                        altError: altError,
                        onClearAltError: onClearAltError,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
