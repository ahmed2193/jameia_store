import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

// ── Completed-order review-star row ───────────────────────────────────────────

class ReviewStars extends StatelessWidget {
  const ReviewStars({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Bundle: completed cards ship `order_evaluate_star*` — a prompt to rate the
    // order. Tapping any star opens the full review flow (order_review). Stars
    // render in the brand rating gold (#EE7F00 warn). Empty until user rates.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Text(
            'orders.rate_your_order'.tr(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
              fontWeight: AppTextStyles.regular,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.s4),
              child: Icon(
                KeetaIcons.star,
                size: 20,
                color: AppColors.warn.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }
}
