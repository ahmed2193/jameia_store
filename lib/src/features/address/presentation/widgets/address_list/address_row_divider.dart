import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// Hairline row divider: 0.5dp #22222214 (RE §5), inset from both edges.
class AddressRowDivider extends StatelessWidget {
  const AddressRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSize.s0_5,
      thickness: AppSize.s0_5,
      indent: AppSpacing.s12,
      endIndent: AppSpacing.s12,
      color: AppColors.rowDividerInk,
    );
  }
}
