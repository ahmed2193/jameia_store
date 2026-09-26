import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_loader.dart';

/// End of a destination row (address or branch): a small loader while the
/// server selects it, an underlined "Change" once one is chosen, a chevron
/// before that. The three fade through each other.
class CheckoutDestinationTrailing extends StatelessWidget {
  const CheckoutDestinationTrailing({
    super.key,
    required this.selecting,
    required this.chosen,
    required this.changeLabel,
  });

  final bool selecting;
  final bool chosen;
  final String changeLabel;

  @override
  Widget build(BuildContext context) {
    return FadeThroughSwitcher(
      stateKey: (selecting, chosen),
      alignment: AlignmentDirectional.centerEnd,
      child: selecting
          ? const BrandedLoader.inline(
              size: AppSize.s20,
              color: AppColors.primaryText,
            )
          : chosen
          ? Text(
              changeLabel,
              style: AppTextStyles.label.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primaryText,
              ),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              size: AppSize.s24,
              color: AppColors.tertiaryText,
            ),
    );
  }
}
