import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';

/// Big bold heading above a group of reward cards ("Ready to redeem"); it
/// rises in once, when it first scrolls into view.
class RewardsSectionTitle extends StatelessWidget {
  const RewardsSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      child: ScrollReveal(
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
