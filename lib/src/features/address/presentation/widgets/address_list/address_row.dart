import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import 'address_row_divider.dart';
import 'address_row_tile.dart';

/// One slot of the grouped card: rounded outer corners on the first / last
/// row, a hairline divider above every other row.
class AddressRow extends StatelessWidget {
  const AddressRow({
    super.key,
    required this.address,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final JameiaAddressEntity address;
  final int index;
  final bool isFirst;
  final bool isLast;

  static const Radius _corner = Radius.circular(AppRadius.card);

  @override
  Widget build(BuildContext context) {
    return StaggerEntrance(
      index: index,
      child: Material(
        color: AppColors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? _corner : Radius.zero,
          bottom: isLast ? _corner : Radius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFirst) const AddressRowDivider(),
            AddressRowTile(address: address),
          ],
        ),
      ),
    );
  }
}
