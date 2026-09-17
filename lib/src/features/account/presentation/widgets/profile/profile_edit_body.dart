import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_form.dart';

/// Switches the screen on "do we have a customer yet": loader, the form, a
/// sign-in prompt for guests (deep link / expired session) or a retry.
/// Rebuilds only when that answer changes — never while typing or saving.
class ProfileEditBody extends StatelessWidget {
  const ProfileEditBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (previous, current) =>
          (previous.customer == null) != (current.customer == null) ||
          (current.customer == null && previous.status != current.status),
      builder: (context, state) {
        if (state.customer != null) return const ProfileForm();
        if (state.isSignedOut) {
          return EmptyStateView(
            message: 'profile.sign_in_subtitle'.tr(),
            icon: Icons.lock_outline_rounded,
            actionLabel: 'profile.sign_in_title'.tr(),
            onAction: () => context.go(Routes.login),
          );
        }
        return state.status == ProfileStatus.error
            ? ErrorView(onRetry: context.read<ProfileCubit>().load)
            : const AppLoader();
      },
    );
  }
}
