import 'package:flutter/material.dart';

import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../widgets/settings_cells.dart';

/// KeeTa `mach_pro_sailor_mine_settings` (Mine → Settings, v0.0.41) — faithful
/// 1:1 clone of the account settings surface.
///
/// Pure UI / device-preference state, so this screen owns its toggles locally
/// (a [StatefulWidget]) instead of going through a cubit + [KeetaRepository] —
/// there is no server-backed settings data in the dummy repository. KeeTa's
/// real screen drives `getMyPageSettingModule` / `setUserInfo`; here the rows
/// flip in-place and Log out / Clear cache are demo no-ops.
///
/// Sections (KeeTa order): Language (EN / AR), Notifications switch, Account &
/// security, Privacy, Clear cache, About (→ [Routes.mineAbout]), Log out.
class MineSettingsScreen extends StatefulWidget {
  const MineSettingsScreen({super.key});

  @override
  State<MineSettingsScreen> createState() => _MineSettingsScreenState();
}

class _MineSettingsScreenState extends State<MineSettingsScreen> {
  /// `true` = English, `false` = العربية (Arabic). Local preview state only.
  bool _english = true;

  /// Push-notification master switch. Local preview state only.
  bool _notifications = true;

  void _setLanguage(bool english) {
    if (_english == english) return;
    setState(() => _english = english);
  }

  void _toggleNotifications(bool value) =>
      setState(() => _notifications = value);

  void _clearCache() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Cache cleared'),
        ),
      );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r2)),
      ),
      builder: (sheetContext) => const _LogoutSheet(),
    );
    if (!mounted || confirmed != true) return;
    // Demo clone: route back to login (no real session to clear).
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

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
          icon: const Icon(KeetaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Settings',
          style:
              AppTextStyles.headingLarge.copyWith(fontWeight: AppTextStyles.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            children: [
              // ── Language + notifications group ──────────────────────────────
              SettingsGroup(
                children: [
                  _LanguageRow(
                    english: _english,
                    onSelect: _setLanguage,
                  ),
                  const SettingsCellDivider(),
                  SettingsSwitchCell(
                    label: 'Notifications',
                    value: _notifications,
                    onChanged: _toggleNotifications,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              // ── Account / privacy group ────────────────────────────────────
              SettingsGroup(
                children: [
                  SettingsNavCell(
                    label: 'Account and security',
                    onTap: () {},
                  ),
                  const SettingsCellDivider(),
                  SettingsNavCell(
                    label: 'Privacy',
                    onTap: () {},
                  ),
                  const SettingsCellDivider(),
                  SettingsNavCell(
                    label: 'Clear cache',
                    trailingText: '12.4 MB',
                    onTap: _clearCache,
                  ),
                  const SettingsCellDivider(),
                  SettingsNavCell(
                    label: 'About',
                    onTap: () => Navigator.pushNamed(context, Routes.mineAbout),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              // ── Log out ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12),
                child: _LogoutButton(onTap: _confirmLogout),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language selector row ───────────────────────────────────────────────────

/// "Language" cell with an inline EN / AR segmented toggle on the trailing edge.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.english, required this.onSelect});

  final bool english;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        children: [
          Expanded(
            child: Text('Language', style: AppTextStyles.headingMedium),
          ),
          _LangSegment(
            english: english,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _LangSegment extends StatelessWidget {
  const _LangSegment({required this.english, required this.onSelect});

  final bool english;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.mediumBackground,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'EN',
            selected: english,
            onTap: () => onSelect(true),
          ),
          _LangChip(
            label: 'العربية',
            selected: !english,
            onTap: () => onSelect(false),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.r6),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.primaryText,
            fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
          ),
        ),
      ),
    );
  }
}

// ── Log out ─────────────────────────────────────────────────────────────────

/// Red full-width log-out button (KeeTa's destructive CTA styling).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.r3),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r3),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              'Log out',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.error,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmation bottom-sheet for the destructive log-out action.
class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Log out of KeeTa?',
              style: AppTextStyles.headingLarge
                  .copyWith(fontWeight: AppTextStyles.bold),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'You can sign back in any time.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.s20),
            AppButton(
              label: 'Log out',
              color: AppColors.errorBg,
              foreground: AppColors.error,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.s8),
            AppOutlineButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
