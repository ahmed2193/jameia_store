import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_menu_cell.dart';

/// Hairline between two Mine menu rows, inset to where the labels start.
class MineMenuDivider extends StatelessWidget {
  const MineMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: MineMenuCell.labelStart),
      child: SizedBox(
        height: AppSize.s0_5,
        width: double.infinity,
        child: ColoredBox(color: AppColors.overlayDivider),
      ),
    );
  }
}
