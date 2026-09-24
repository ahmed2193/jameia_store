import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import 'address_label_glyph.dart';
import 'address_row_actions.dart';
import 'address_row_details.dart';

/// Tag glyph, label + address line + phone, and the edit / delete actions.
/// Tapping the row picks the address: the route pops with it (Home / checkout
/// reuse the list as a picker).
class AddressRowTile extends StatelessWidget {
  const AddressRowTile({super.key, required this.address});

  final JameiaAddressEntity address;

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
    // whole row gives the subtle press feel.
    return PressScale(
      child: InkWell(
        onTap: () => context.pop(address),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s2),
                child: AddressLabelGlyph(label: address.labelKind),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(child: AddressRowDetails(address: address)),
              const SizedBox(width: AppSpacing.s8),
              AddressRowActions(address: address),
            ],
          ),
        ),
      ),
    );
  }
}
