import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_form.dart';

/// What the edit-profile body shows.
enum ProfileEditScreen { loading, form, signedOut, error }

/// Switches the screen on "do we have a customer yet": loader, the form, a
/// sign-in prompt for guests (deep link / expired session) or a retry, fading
/// through from one to the next. Rebuilds only when that answer changes —
/// never while typing or saving.
class ProfileEditBody extends StatelessWidget {
  const ProfileEditBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (previous, current) =>
          (previous.customer == null) != (current.customer == null) ||
          (current.customer == null && previous.status != current.status),
      builder: (context, state) {
        final screen = switch (state) {
          ProfileState(customer: _?) => ProfileEditScreen.form,
          ProfileState(isSignedOut: true) => ProfileEditScreen.signedOut,
          ProfileState(status: ProfileStatus.error) => ProfileEditScreen.error,
          _ => ProfileEditScreen.loading,
        };
        return FadeThroughSwitcher(
          stateKey: screen,
          child: switch (screen) {
            ProfileEditScreen.form => const ProfileForm(),
            ProfileEditScreen.signedOut => EmptyStateView(
              message: 'profile.sign_in_subtitle'.tr(),
              icon: Icons.lock_outline_rounded,
              actionLabel: 'profile.sign_in_title'.tr(),
              onAction: () => context.go(Routes.login),
            ),
            ProfileEditScreen.error => ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: context.read<ProfileCubit>().load,
            ),
            ProfileEditScreen.loading => const AppLoader(),
          },
        );
      },
    );
  }
}
