import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/light_sweep.dart';

/// "PRO" pill next to a Hero Pro member's name: the Pro gradient, a small
/// crown and a slow light sweep — the Mine tab's one ambient loop, running
/// only while the tab is on screen and the header is fully open. [opacity]
/// fades its colours as the header collapses.
class MineProBadge extends StatelessWidget {
  const MineProBadge({super.key, this.opacity = 1});

  final double opacity;

  static const double _crown = AppSize.s12;
  static final BorderRadius _radius = BorderRadius.circular(AppRadius.pill);

  @override
  Widget build(BuildContext context) {
    final white = AppColors.white.withValues(alpha: opacity);
    return LightSweep(
      active: opacity == 1 && Visibility.of(context),
      borderRadius: _radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              for (final color in AppColors.proGradient)
                color.withValues(alpha: opacity),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: _crown,
                color: AppColors.proAmber.withValues(alpha: opacity),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'account.pro_badge'.tr(),
                style: AppTextStyles.captionMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                  color: white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
