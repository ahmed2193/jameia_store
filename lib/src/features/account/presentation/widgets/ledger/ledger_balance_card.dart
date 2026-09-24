import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Brand-green balance card at the top of the wallet / points screen: white
/// label, big value and an optional caption.
class LedgerBalanceCard extends StatelessWidget {
  const LedgerBalanceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption = '',
  });

  final IconData icon;
  final String label;
  final String value;

  /// A secondary line (what the points are worth); hidden when empty.
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s16),
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.brandForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.brandForeground,
                  ),
                ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    caption,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.brandForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(icon, size: AppSize.s40, color: AppColors.brandForeground),
        ],
      ),
    );
  }
}
