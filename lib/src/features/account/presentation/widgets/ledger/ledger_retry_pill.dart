import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Outlined "Retry" pill of the history footer after a next page failed.
class LedgerRetryPill extends StatelessWidget {
  const LedgerRetryPill({super.key, required this.onTap});

  static const double _height = AppSize.s44;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        child: PressScale(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.divider),
            ),
            child: SizedBox(
              height: _height,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s14,
                  0,
                  AppSpacing.s16,
                  0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeroIcon(
                      HeroIcons.refresh,
                      size: AppSize.s18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      'retry'.tr(),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
