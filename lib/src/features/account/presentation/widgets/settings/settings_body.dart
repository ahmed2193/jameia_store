import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import 'settings_clear_cache_tile.dart';
import 'settings_haptics_tile.dart';
import 'settings_language_tile.dart';
import 'settings_logout_tile.dart';
import 'settings_notifications_tile.dart';
import 'settings_section.dart';
import 'settings_tile.dart';
import 'settings_tone.dart';

/// The Settings list: Preferences (language, notifications, vibration),
/// General (account, privacy, cache, about) and — signed in — Log out. The
/// groups rise in once when the screen opens.
///
/// Every label is resolved here and handed down, so a language switch (a
/// new [languageCode]) re-labels the whole screen in place, without
/// rebuilding the rows or replaying their entrance.
class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key, required this.languageCode});

  /// CMS page with the privacy policy (`GET /v1/pages/privacy`).
  static const String _privacySlug = 'privacy';

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return EntranceCascade(
      child: ContentClamp(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            MediaQuery.paddingOf(context).bottom + AppSpacing.s32,
          ),
          children: [
            EntranceCascadeItem(
              index: 0,
              child: SettingsSection(
                title: 'settings.section_preferences'.tr(),
                children: [
                  SettingsLanguageTile(
                    title: 'settings.language'.tr(),
                    languageCode: languageCode,
                  ),
                  SettingsNotificationsTile(
                    title: 'settings.notifications'.tr(),
                    subtitle: 'settings.notifications_hint'.tr(),
                  ),
                  SettingsHapticsTile(
                    title: 'settings.vibration'.tr(),
                    subtitle: 'settings.vibration_hint'.tr(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            EntranceCascadeItem(
              index: 1,
              child: SettingsSection(
                title: 'settings.section_general'.tr(),
                children: [
                  SettingsTile(
                    icon: Icons.shield_outlined,
                    tone: SettingsTone.green,
                    title: 'settings.account_security'.tr(),
                    onTap: () => context.push(Routes.profileEdit),
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    tone: SettingsTone.violet,
                    title: 'settings.privacy'.tr(),
                    onTap: () =>
                        context.push(Routes.contentPage, extra: _privacySlug),
                  ),
                  SettingsClearCacheTile(title: 'settings.clear_cache'.tr()),
                  SettingsTile(
                    icon: Icons.info_outline_rounded,
                    tone: SettingsTone.neutral,
                    title: 'settings.about'.tr(),
                    onTap: () => context.push(Routes.mineAbout),
                  ),
                ],
              ),
            ),
            EntranceCascadeItem(
              index: 2,
              child: SettingsLogoutTile(title: 'settings.logout'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
