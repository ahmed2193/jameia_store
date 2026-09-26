import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One wallet / points history row: the kind in a soft rounded tile, title,
/// time (+ an optional detail line) and the signed amount at the end —
/// green for credits, neutral ink for debits. Read as one node by screen
/// readers.
class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    required this.amount,
    required this.isCredit,
    this.detail = '',
  });

  /// Side of the kind tile; the row divider starts after it ([textInset]).
  static const double iconBox = AppSize.s44;
  static const double textInset = AppSpacing.s16 + iconBox + AppSpacing.s12;
  static const int _detailLines = 2;

  final IconData icon;
  final String title;

  /// When the line was booked ("10:12 AM"); its day is the group title.
  final String time;

  /// Signed and formatted ("+KD 1.250", "−40 pts").
  final String amount;
  final bool isCredit;

  /// A note from the store or an expiry line; hidden when empty.
  final String detail;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isCredit
                    ? AppColors.brandLightBg
                    : AppColors.smallBackground,
                borderRadius: BorderRadius.circular(AppRadius.r4),
              ),
              child: SizedBox.square(
                dimension: iconBox,
                child: Icon(
                  icon,
                  size: AppSize.s22,
                  color: isCredit
                      ? AppColors.primaryDark
                      : AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    time,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      detail,
                      maxLines: _detailLines,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Text(
              amount,
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
                color: isCredit ? AppColors.primaryDark : AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
