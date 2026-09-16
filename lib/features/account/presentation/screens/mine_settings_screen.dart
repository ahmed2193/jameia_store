import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/keeta_icons.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/setting_cubit.dart';
import '../widgets/language_icon_button.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
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
  /// Push-notification master switch. Local preview state only.
  bool _notifications = true;

  void _toggleNotifications(bool value) =>
      setState(() => _notifications = value);

  void _clearCache() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('settings.cache_cleared'.tr()),
        ),
      );
  }

  Future<void> _confirmLogout() async {
    // KeeTa's log-out confirmation is a CENTERED modal dialog (bundle class
    // `g8998f`: 24dp horizontal margins, 8dp radius, scale-in `a06000` + fade-in
    // `da8c88`, 300ms ease-in-out) — not a bottom sheet. [showKeetaDialog]
    // supplies that fade + scale entrance transition.
    final confirmed = await showKeetaDialog<bool>(
      context,
      barrierLabel: 'settings.logout_barrier'.tr(),
      barrierColor: AppColors.overlayPrimary,
      pageBuilder: (_) => const _LogoutDialog(),
    );
    if (!mounted || confirmed != true) return;
    // Demo clone: route back to login (no real session to clear).
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole screen on a language change so the AppBar title + every
    // cell re-localize live while the user is still on this screen (which hosts
    // the language toggle). `.tr()` is context-free, so without this BlocBuilder
    // only the direction would flip and the text would stay in the old language.
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      buildWhen: (p, c) => p.locale != c.locale,
      builder: (context, _) => Scaffold(
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
            'settings.title'.tr(),
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.s12),
              child: Center(child: LanguageIconButton()),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ContentClamp(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              children: [
                // ── Language + notifications group ──────────────────────────────
                StaggerEntrance(
                  index: 0,
                  child: SettingsGroup(
                    children: [
                      BlocBuilder<LocalizationCubit, LocalizationState>(
                        builder: (context, locState) => _LanguageRow(
                          english: locState.isEnglish,
                          onSelect: (english) => context
                              .read<SettingCubit>()
                              .changeLanguage(context, english ? 'en' : 'ar'),
                        ),
                      ),
                      const SettingsCellDivider(),
                      SettingsSwitchCell(
                        label: 'settings.notifications'.tr(),
                        value: _notifications,
                        onChanged: _toggleNotifications,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                // ── Account / privacy group ────────────────────────────────────
                StaggerEntrance(
                  index: 1,
                  child: SettingsGroup(
                    children: [
                      SettingsNavCell(
                        label: 'settings.account_security'.tr(),
                        onTap: () {},
                      ),
                      const SettingsCellDivider(),
                      SettingsNavCell(
                        label: 'settings.privacy'.tr(),
                        onTap: () {},
                      ),
                      const SettingsCellDivider(),
                      SettingsNavCell(
                        label: 'settings.clear_cache'.tr(),
                        trailingText: '12.4 MB',
                        onTap: _clearCache,
                      ),
                      const SettingsCellDivider(),
                      SettingsNavCell(
                        label: 'settings.about'.tr(),
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.mineAbout),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                // ── Log out ────────────────────────────────────────────────────
                StaggerEntrance(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                    ),
                    child: _LogoutButton(onTap: _confirmLogout),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
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
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'settings.language'.tr(),
              style: AppTextStyles.headingMedium,
            ),
          ),
          _LangSegment(english: english, onSelect: onSelect),
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
        duration: MotionGuard.duration(context, AppMotion.fast),
        curve: MotionGuard.curve(context, AppMotion.signature),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s6,
        ),
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
    // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
    // whole destructive CTA gives the subtle press feel.
    return PressScale(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSize.r8),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSize.r8),
          onTap: onTap,
          child: SizedBox(
            height: 65,
            child: Center(
              child: Text(
                'settings.logout'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.logoutRed,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered confirmation dialog for the destructive log-out action.
///
/// Mirrors KeeTa's bundle card `g8998f` (centered, 24dp horizontal margins, 8dp
/// radius, white) with `ed427c` content padding (28dp top / 16dp sides / 12dp
/// bottom), title `g71382` (18dp bold) and subtitle `ba78c7` (14dp, 6dp gap).
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSize.r8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'settings.logout_confirm'.tr(),
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
                const SizedBox(height: AppSpacing.s20),
                AppButton(
                  label: 'settings.logout'.tr(),
                  color: AppColors.primary,
                  foreground: AppColors.primaryText,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.s8),
                AppOutlineButton(
                  label: 'common.cancel'.tr(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
