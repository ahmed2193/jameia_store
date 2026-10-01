import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../auth/presentation/cubit/auth_session_state.dart';
import 'settings_section.dart';
import 'settings_tile.dart';
import 'settings_tone.dart';

/// "Log out" in its own card at the end of Settings, shown only while
/// signed in. It asks first; its confirm button gives the one warning
/// haptic (§9.5 destructive confirm), then the session ends
/// (revoked server-side, wiped locally even offline) and the whole stack is
/// replaced by login.
class SettingsLogoutTile extends StatelessWidget {
  const SettingsLogoutTile({super.key, required this.title});

  final String title;

  Future<void> _logOut(BuildContext context) async {
    final session = context.read<AuthSessionCubit>();
    final confirmed = await showHeroConfirmDialog(
      context,
      title: 'settings.logout_confirm'.tr(),
      message: 'settings.logout_subtitle'.tr(),
      icon: HeroIcons.logout,
      confirmLabel: 'settings.logout'.tr(),
      destructive: true,
    );
    if (!confirmed) return;
    await session.signOut();
    if (!context.mounted) return;
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AuthSessionCubit,
      AuthSessionState,
      ({bool visible, bool busy})
    >(
      selector: (state) => (
        visible: state.isSignedIn || state.isSigningOut,
        busy: state.isSigningOut,
      ),
      builder: (context, logout) {
        if (!logout.visible) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.s24),
          child: SettingsSection(
            children: [
              SettingsTile(
                icon: HeroIcons.logout,
                tone: SettingsTone.danger,
                title: title,
                titleColor: AppColors.logoutRed,
                chevron: false,
                // The page's busy overlay shows the sign-out in flight.
                onTap: logout.busy ? null : () => _logOut(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
