import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';

/// Hairline between two quick stats.
class MineStatDivider extends StatelessWidget {
  const MineStatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: AppSize.s0_5,
      height: AppSize.s44,
      child: ColoredBox(color: AppColors.overlayDivider),
    );
  }
}
