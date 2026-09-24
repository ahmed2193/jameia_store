import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// Invite / growth banner (bundle `fd9b28`): 208° #FFFEE0→#FFF gradient, 1dp
/// border, radius 12dp; animated invite badge, title, subtitle, arrow.
class MineInviteBanner extends StatelessWidget {
  const MineInviteBanner({super.key});

  /// ~208° in `Alignment` terms, with the tint fading out at 42%.
  static const Alignment _gradientBegin = Alignment(-0.53, -0.85);
  static const Alignment _gradientEnd = Alignment(0.53, 0.85);
  static const List<double> _gradientStops = [0.0, 0.42];

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => context.push(Routes.inviteFriends),
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: _gradientBegin,
            end: _gradientEnd,
            stops: _gradientStops,
            colors: [AppColors.inviteBannerBg, AppColors.white],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.overlayDivider,
            width: AppSize.s1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                JameiaAssets.mineBannerBg,
                width: AppSize.s50,
                height: AppSize.s50,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'account.invite_title'.tr(),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'account.invite_subtitle'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Image.asset(
                JameiaAssets.mineArrowCell,
                width: AppSize.s20,
                height: AppSize.s20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
