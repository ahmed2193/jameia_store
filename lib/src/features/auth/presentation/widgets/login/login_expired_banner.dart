import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Explains why the user landed on login after the session could not be
/// refreshed (shown when the route was opened with the expired flag). A
/// notice, not an error: a warm amber card with the lock-clock badge.
class LoginExpiredBanner extends StatelessWidget {
  const LoginExpiredBanner({super.key});

  static const double _badge = AppSize.s32;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accent3Light,
          borderRadius: BorderRadius.circular(AppRadius.r3),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.s12),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: _badge,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: HeroIcon(
                    HeroIcons.lockClock,
                    color: AppColors.accent3Dark,
                    size: AppSize.s18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  'auth.session_expired'.tr(),
                  style: AppTextStyles.subheadingMedium.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
