import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One wallet / points history row: kind icon, title, date (+ an optional
/// detail line) and the signed amount — green for credits.
class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.detail = '',
  });

  final IconData icon;
  final String title;
  final String date;

  /// Signed and formatted ("+KD 1.250", "−40 pts").
  final String amount;
  final bool isCredit;

  /// A note from the store or an expiry line; hidden when empty.
  final String detail;

  @override
  Widget build(BuildContext context) {
    final accent = isCredit ? AppColors.primaryDark : AppColors.secondaryText;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSize.s40,
            height: AppSize.s40,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.brandLightBg
                  : AppColors.smallBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSize.s20, color: accent),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  date,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    detail,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            amount,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: AppTextStyles.bold,
              color: isCredit ? AppColors.primaryDark : AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
