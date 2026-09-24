import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Heading above the history rows ("Transactions", "Points history").
class LedgerSectionTitle extends StatelessWidget {
  const LedgerSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.s16,
        end: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s4,
      ),
      child: Text(
        text,
        style: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
