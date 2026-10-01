import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../cubit/loyalty_program_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile/profile_edit_body.dart';
import '../widgets/profile/profile_edit_listener.dart';

/// Mine → Edit profile: form → `PATCH /v1/account/profile`. The form starts
/// from the session's customer; it asks `GET /v1/account/me` only when the
/// server has not confirmed that copy yet this run (the device copy shown
/// offline, or no customer at all). Every customer record the server hands
/// back also updates the app-global session (see [ProfileEditListener]), so
/// the Mine header / wallet never lag behind this page.
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  ProfileCubit _createProfile(BuildContext context) {
    final session = context.read<AuthSessionCubit>().state;
    final cubit = sl<ProfileCubit>(param1: session.customer);
    if (!session.isVerified || session.customer == null) cubit.load();
    return cubit;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: _createProfile),
        // The profile-bonus hint; the programme is kept for the whole run.
        BlocProvider(create: (_) => sl<LoyaltyProgramCubit>()..load()),
      ],
      child: ProfileEditListener(
        // Saving holds the screen; the check shows until the page leaves.
        child: CubitBusyOverlay<ProfileCubit, ProfileState>(
          busyOf: (state) => state.status == ProfileStatus.saving,
          doneOf: (state) => state.status == ProfileStatus.saved,
          failOf: (state) => state.status == ProfileStatus.error,
          label: 'profile.saving'.tr(),
          doneLabel: 'profile.saved'.tr(),
          child: Scaffold(
            backgroundColor: AppColors.mediumBackground,
            appBar: HeroTitleBar(title: 'profile.title'.tr()),
            body: const SafeArea(
              top: false,
              child: ContentClamp(child: ProfileEditBody()),
            ),
          ),
        ),
      ),
    );
  }
}
