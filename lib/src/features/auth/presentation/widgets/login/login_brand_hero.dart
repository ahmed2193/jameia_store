import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/responsive/app_size.dart';
import 'login_brand_logo.dart';

/// The brand card at the top of login: a deep → light green gradient with
/// two soft rings in the end corner, the app icon, the wordmark and the
/// tagline. Static apart from the logo's one-time entrance; the whole card
/// folds away while the keyboard is up ([LoginHeroCollapse]).
class LoginBrandHero extends StatelessWidget {
  const LoginBrandHero({super.key});

  static const List<Color> _gradient = [
    AppColors.primaryDark,
    AppColors.primary,
    AppColors.brandDarkBg,
  ];
  static const double _shadowAlpha = 0.28;
  static const Offset _shadowOffset = Offset(0, AppSpacing.s8);
  static final List<BoxShadow> _shadow = [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: _shadowAlpha),
      offset: _shadowOffset,
      blurRadius: AppSize.s24,
      spreadRadius: -AppSpacing.s6,
    ),
  ];
  static const double _mutedAlpha = 0.9;
  static final Color _muted = AppColors.white.withValues(alpha: _mutedAlpha);
  static const double _ringAlpha = 0.14;
  static final Color _ring = AppColors.white.withValues(alpha: _ringAlpha);
  static const double _bigRingOverhang = -AppSpacing.s56;
  static const double _bigRingWidth = AppSpacing.s28;
  static const double _smallRingTop = AppSize.s100;
  static const double _smallRingEnd = AppSpacing.s32;
  static const double _smallRingWidth = AppSpacing.s10;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r2);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _shadow,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: _gradient,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            PositionedDirectional(
              top: _bigRingOverhang,
              end: _bigRingOverhang,
              child: SizedBox.square(
                dimension: AppSize.s200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _ring, width: _bigRingWidth),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: _smallRingTop,
              end: _smallRingEnd,
              child: SizedBox.square(
                dimension: AppSize.s44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _ring, width: _smallRingWidth),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s20,
                AppSpacing.s20,
                AppSpacing.s20,
                AppSpacing.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoginBrandLogo(),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.brandForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'auth.hero_tagline'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: AppTextStyles.medium,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(width: double.infinity, child: card);
  }
}
