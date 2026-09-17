import 'package:flutter/material.dart';

import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

/// Drawn radio circle — a yellow dot inside a ring when [selected]. Extracted
/// from the identical `_Radio` widgets in the address create/edit + map-pick
/// screens.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.s20,
      height: AppSize.s20,
      margin: const EdgeInsetsDirectional.only(top: AppSpacing.s2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
          width: AppSize.s2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? PopScale(
              popKey: selected,
              child: Container(
                width: AppSize.s10,
                height: AppSize.s10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
