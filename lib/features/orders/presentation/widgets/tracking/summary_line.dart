import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class SummaryLine extends StatelessWidget {
  const SummaryLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    // KeeTa total row: label secondaryText 14dp, value Bold 14dp primaryText.
    final valueStyle = emphasize
        ? AppTextStyles.subheadingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          )
        : AppTextStyles.bodyLarge;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
