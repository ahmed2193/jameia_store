import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import 'settings_icon_badge.dart';
import 'settings_tone.dart';

/// Centered "Log out?" card. Pops `true` when the customer confirms.
class SettingsLogoutDialog extends StatelessWidget {
  const SettingsLogoutDialog({super.key});

  static const double _maxWidth = AppSize.s350;

  @override
  Widget build(BuildContext context) {
    final title = 'settings.logout_confirm'.tr();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r2),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s24,
                  AppSpacing.s28,
                  AppSpacing.s24,
                  AppSpacing.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SettingsIconBadge(
                      icon: HeroIcons.logout,
                      tone: SettingsTone.danger,
                      dimension: AppSize.s56,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingLarge.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      'settings.logout_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    AppButton(
                      label: 'settings.logout'.tr(),
                      color: AppColors.logoutRed,
                      foreground: AppColors.white,
                      // A destructive confirm: the one warning haptic.
                      haptic: HapticKind.warning,
                      onPressed: () => context.pop(true),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SizedBox(
                      width: double.infinity,
                      child: AppOutlineButton(
                        label: 'common.cancel'.tr(),
                        height: AppSize.s48,
                        onPressed: () => context.pop(false),
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
