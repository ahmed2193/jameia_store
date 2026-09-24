import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';

/// Hairline between two quick stats (bundle `c5b706`: 0.5dp × 35dp).
class MineStatDivider extends StatelessWidget {
  const MineStatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.s0_5,
      height: AppSize.s35,
      color: AppColors.overlayDivider,
    );
  }
}
