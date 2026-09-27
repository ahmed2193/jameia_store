import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/branded_loader.dart';
import '../../../../../core/widgets/jameia_list_row.dart';

/// End of a destination row (address or branch): a small loader while the
/// server selects it, the flat row's ink chevron otherwise. The two fade
/// through each other.
class CheckoutDestinationTrailing extends StatelessWidget {
  const CheckoutDestinationTrailing({super.key, required this.selecting});

  final bool selecting;

  @override
  Widget build(BuildContext context) {
    return FadeThroughSwitcher(
      stateKey: selecting,
      alignment: AlignmentDirectional.centerEnd,
      child: selecting
          ? const BrandedLoader.inline(
              size: JameiaListRow.denseLeadSize,
              color: AppColors.primaryText,
            )
          : const Icon(
              Icons.chevron_right_rounded,
              size: JameiaListRow.denseLeadSize,
              color: AppColors.primaryText,
            ),
    );
  }
}
