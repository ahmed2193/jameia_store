import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';

/// The drag handle at the top of every bottom sheet: a short grey pill 8 dp
/// under the sheet's edge. [HeroSheetHeader] draws it; a sheet without a
/// title (an action menu, a centred prompt) draws it alone.
class HeroSheetHandle extends StatelessWidget {
  const HeroSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: AppSpacing.s8),
        child: Center(
          child: SizedBox(
            width: AppSize.s36,
            height: AppSize.s4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.disabledText,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
