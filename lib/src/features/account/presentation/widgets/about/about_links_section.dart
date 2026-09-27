import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/navigation/navigation.dart';
import '../settings/settings_section.dart';
import '../settings/settings_tile.dart';
import '../settings/settings_tone.dart';
import 'about_version_chip.dart';

/// Legal and feedback rows of About: the terms and the privacy policy (the
/// backend's CMS pages), the open-source licenses and "Rate us".
class AboutLinksSection extends StatelessWidget {
  const AboutLinksSection({super.key});

  /// CMS pages (`GET /v1/pages/:slug`).
  static const String _termsSlug = 'terms';
  static const String _privacySlug = 'privacy';

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      children: [
        SettingsTile(
          icon: Icons.description_outlined,
          tone: SettingsTone.sky,
          title: 'account.terms_of_service'.tr(),
          onTap: () => context.push(Routes.contentPage, extra: _termsSlug),
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          tone: SettingsTone.violet,
          title: 'account.privacy_policy'.tr(),
          onTap: () => context.push(Routes.contentPage, extra: _privacySlug),
        ),
        SettingsTile(
          icon: Icons.code_rounded,
          tone: SettingsTone.neutral,
          title: 'account.licenses'.tr(),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'account.app_name'.tr(),
            applicationVersion: AboutVersionChip.appVersion,
          ),
        ),
        SettingsTile(
          icon: Icons.star_outline_rounded,
          tone: SettingsTone.amber,
          title: 'account.rate_us'.tr(),
          onTap: () => showHeroSnackBar(
            context,
            'account.rate_us_thanks'.tr(),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ],
    );
  }
}
