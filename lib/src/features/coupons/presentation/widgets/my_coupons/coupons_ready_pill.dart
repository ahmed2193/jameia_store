import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Frosted pill on the savings card: "Coupons ready: N".
class CouponsReadyPill extends StatelessWidget {
  const CouponsReadyPill({super.key, required this.count});

  final int count;

  static const double _fillAlpha = 0.2;
  static final Color _fill = AppColors.white.withValues(alpha: _fillAlpha);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeroIcon(
              HeroIcons.tag,
              size: AppSize.s14,
              color: AppColors.white,
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                'coupons.ready_count'.tr(namedArgs: {'count': '$count'}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
