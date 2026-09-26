import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// The points of a reward card in big digits, centred under the discount
/// pill: white on a ready card, deep orange under a lock on a locked one.
class RewardCardFace extends StatelessWidget {
  const RewardCardFace({
    super.key,
    required this.points,
    required this.isLocked,
  });

  final int points;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final ink = isLocked ? AppColors.accent3Dark : AppColors.white;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s10,
        AppSpacing.s40,
        AppSpacing.s10,
        AppSpacing.s10,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked)
                Icon(Icons.lock_rounded, size: AppSize.s24, color: ink),
              Text(
                '$points',
                style: AppTextStyles.digits(AppSize.font40)
                    .copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
