import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/marketing_moments.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../widgets/settings_cells.dart';

/// Jameia `mach_pro_sailor_mine_about` (Mine → About, v0.0.26) — faithful 1:1
/// clone of the About surface.
///
/// Pure static informational page (no server-backed data), so it is a plain
/// [StatelessWidget] — no cubit / [JameiaRepository] needed. Jameia's real screen
/// renders: the app logo + version header, a grouped list of legal / engagement
/// rows (Terms of service, Privacy policy, Licenses, Rate us, Follow us), and a
/// copyright footer. The legal rows have no destination route in the clone, so
/// they are demo no-ops; "Follow us" expands an inline social row, "Rate us"
/// shows a thank-you snackbar.
class MineAboutPage extends StatelessWidget {
  const MineAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'account.about'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
            children: const [
              // ── App logo + version header ──────────────────────────────────
              StaggerEntrance(index: 0, child: _AboutHeader()),
              SizedBox(height: AppSpacing.s24),
              // ── Legal / engagement rows ────────────────────────────────────
              StaggerEntrance(index: 1, child: _AboutRows()),
              SizedBox(height: AppSpacing.s24),
              // ── Copyright footer ───────────────────────────────────────────
              StaggerEntrance(index: 2, child: _CopyrightFooter()),
              SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App version (build-meta; static in the clone) ────────────────────────────

const String _kAppVersion = '0.0.26';

// ── Logo + version header ────────────────────────────────────────────────────

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AppLogo(),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'account.app_name'.tr(),
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'account.version'.tr(namedArgs: {'version': _kAppVersion}),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.versionText,
          ),
        ),
      ],
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSize.r8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Image.asset(
          JameiaAssets.logo,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Icon(JameiaIcons.info, size: 40, color: AppColors.black),
        ),
      ),
    );
  }
}

// ── Grouped legal / engagement rows ──────────────────────────────────────────

class _AboutRows extends StatefulWidget {
  const _AboutRows();

  @override
  State<_AboutRows> createState() => _AboutRowsState();
}

class _AboutRowsState extends State<_AboutRows> {
  /// Whether the inline social row under "Follow us" is expanded.
  bool _followExpanded = false;

  void _toggleFollow() => setState(() => _followExpanded = !_followExpanded);

  void _rateUs() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('account.rate_us_thanks'.tr()),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsNavCell(label: 'account.terms_of_service'.tr(), onTap: () {}),
        const SettingsCellDivider(),
        SettingsNavCell(label: 'account.privacy_policy'.tr(), onTap: () {}),
        const SettingsCellDivider(),
        SettingsNavCell(label: 'account.licenses'.tr(), onTap: () {}),
        const SettingsCellDivider(),
        SettingsNavCell(label: 'account.rate_us'.tr(), onTap: _rateUs),
        const SettingsCellDivider(),
        SettingsNavCell(label: 'account.follow_us'.tr(), onTap: _toggleFollow),
        // Inline social row reveals with a height + fade accordion when
        // "Follow us" is tapped (real _followExpanded state).
        AnimatedAccordion(
          expanded: _followExpanded,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [SettingsCellDivider(), _SocialRow()],
          ),
        ),
      ],
    );
  }
}

// ── Real Jameia social profiles (followed by "Follow us") ─────────────────────
//
// JameiaIcons (the real `wm_c_iconfont`) has NO brand-specific Facebook /
// Instagram / X glyphs, so per the design-guard fallback ("Material icons only
// where a glyph is missing") each brand uses a DISTINCT Material brand-shaped
// glyph + a DISTINCT semantic token tint — never the same generic share icon
// for all three. Raw `Color(0x..)` is banned in feature code, so each chip
// borrows an existing semantic token that reads as that brand (blue / red /
// black). There is no `url_launcher` dependency in the clone, so tapping a chip
// surfaces the real public handle via a snackbar (demo no-op for the outbound
// open, but each destination is distinct and real).
const List<_SocialLink> _kSocialLinks = <_SocialLink>[
  _SocialLink(
    label: 'Facebook',
    handle: 'facebook.com/Jameia',
    icon: Icons.facebook,
    brand: AppColors.link,
  ),
  _SocialLink(
    label: 'Instagram',
    handle: 'instagram.com/jameia.official',
    icon: Icons.camera_alt_rounded,
    brand: AppColors.accent1,
  ),
  _SocialLink(
    label: 'X',
    handle: 'x.com/Jameia',
    icon: Icons.alternate_email_rounded,
    brand: AppColors.primaryText,
  ),
];

class _SocialLink {
  const _SocialLink({
    required this.label,
    required this.handle,
    required this.icon,
    required this.brand,
  });

  final String label;
  final String handle;
  final IconData icon;
  final Color brand;
}

/// Inline social-handles row revealed when "Follow us" is tapped.
class _SocialRow extends StatelessWidget {
  const _SocialRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s14,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _kSocialLinks.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s8),
            _SocialChip(link: _kSocialLinks[i]),
          ],
        ],
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.link});
  final _SocialLink link;

  void _open(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'account.social_opening'.tr(namedArgs: {'handle': link.handle}),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Passive PressScale (no onTap) so the InkWell keeps its ripple.
    return Expanded(
      child: PressScale(
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(AppRadius.r6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.circular(AppRadius.r6),
            ),
            child: Column(
              children: [
                Icon(link.icon, size: 18, color: link.brand),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  link.label,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Copyright footer ─────────────────────────────────────────────────────────

class _CopyrightFooter extends StatelessWidget {
  const _CopyrightFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'account.copyright'.tr(),
        textAlign: TextAlign.center,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.tertiaryText,
        ),
      ),
    );
  }
}
