import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Big bold heading above the history ("Transactions", "Points history"),
/// the same voice as the Rewards section titles.
class LedgerSectionTitle extends StatelessWidget {
  const LedgerSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s2,
      ),
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
    );
  }
}
