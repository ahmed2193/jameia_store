import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'reward_applied_chip.dart';
import 'reward_progress_bar.dart';

/// Under a reward card's title: the points it costs (+ the "Applied" chip,
/// popping in, while the basket carries it) or, when locked, a mini bar
/// from the balance toward it above the points still missing.
class RewardCardFooter extends StatelessWidget {
  const RewardCardFooter({
    super.key,
    required this.points,
    required this.balance,
    required this.missingPoints,
    required this.isApplied,
  });

  final int points;
  final int balance;

  /// Points still to earn; 0 = ready to redeem.
  final int missingPoints;
  final bool isApplied;

  @override
  Widget build(BuildContext context) {
    final isLocked = missingPoints > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLocked) ...[
          RewardProgressBar(
            current: balance,
            target: points,
            height: AppSize.s6,
            trackColor: AppColors.divider,
            fillColors: const [AppColors.proAmber, AppColors.accent3],
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
        Row(
          children: [
            Flexible(
              child: Text(
                isLocked
                    ? 'loyalty.reward_missing'.tr(
                        namedArgs: {'points': '$missingPoints'},
                      )
                    : 'loyalty.reward_points'.tr(
                        namedArgs: {'points': '$points'},
                      ),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            if (isApplied) ...[
              const SizedBox(width: AppSpacing.s6),
              const PopScale.onMount(child: RewardAppliedChip()),
            ],
          ],
        ),
      ],
    );
  }
}
