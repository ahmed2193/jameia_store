import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/hero_address_entity.dart';
import '../../../../../core/widgets/address_label_icon.dart';
import '../../../../../core/widgets/press_row.dart';
import 'address_row_actions.dart';
import 'address_row_details.dart';

/// Tag glyph, label + address line + phone, and the edit / delete actions.
/// Tapping the row picks the address: the route pops with it (Home / checkout
/// reuse the list as a picker).
class AddressRowTile extends StatelessWidget {
  const AddressRowTile({super.key, required this.address});

  final HeroAddressEntity address;

  @override
  Widget build(BuildContext context) {
    // The edit / delete actions press themselves; the row stays still then.
    return PressRow(
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
              child: AddressLabelIcon(label: address.labelKind),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(child: AddressRowDetails(address: address)),
            const SizedBox(width: AppSpacing.s8),
            AddressRowActions(address: address),
          ],
        ),
      ),
    );
  }
}
