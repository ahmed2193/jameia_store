import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// One label / value line of a price summary (cart, checkout, invoice).
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.headingSmall.copyWith(
            color: AppColors.primaryText,
            fontWeight: AppTextStyles.bold,
          )
        : AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style.copyWith(
              color: valueColor ?? (emphasized ? AppColors.primaryText : null),
            ),
          ),
        ],
      ),
    );
  }
}
