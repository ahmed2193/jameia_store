import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Title of one day of the history ("Today", "Sat, Sep 21"). It pins under
/// the app bar while its day scrolls by, so it is opaque.
class LedgerDayHeader extends StatelessWidget {
  const LedgerDayHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s16,
          AppSpacing.s14,
          AppSpacing.s16,
          AppSpacing.s6,
        ),
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: AppTextStyles.subheadingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
