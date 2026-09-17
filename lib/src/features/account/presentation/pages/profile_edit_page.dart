import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile/profile_edit_app_bar.dart';
import '../widgets/profile/profile_edit_body.dart';

/// Mine → Edit profile: `GET /v1/account/me` → form → `PATCH
/// /v1/account/profile`. Every customer record the server hands back (the
/// refresh on open, the save reply) also updates the app-global session, so
/// the Mine header / wallet never lag behind this page.
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  void _onChange(BuildContext context, ProfileState state) {
    final customer = state.customer;
    if (customer != null) {
      context.read<AuthSessionCubit>().updateCustomer(customer);
    }
    if (state.status == ProfileStatus.saved) {
      showJameiaSnackBar(context, 'profile.saved'.tr());
      context.pop();
      return;
    }
    final failure = state.failure;
    // A failed first load is rendered inline by the body, not toasted.
    if (failure != null && state.customer != null) {
      showJameiaSnackBar(context, failure.localizedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Seed the form with the customer the app already knows, then refresh.
      create: (context) => sl<ProfileCubit>(
        param1: context.read<AuthSessionCubit>().state.customer,
      )..load(),
      child: BlocListener<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.customer != current.customer ||
            (current.failure != null && previous.failure != current.failure),
        listener: _onChange,
        child: const Scaffold(
          backgroundColor: AppColors.mediumBackground,
          appBar: ProfileEditAppBar(),
          body: SafeArea(
            top: false,
            child: ContentClamp(child: ProfileEditBody()),
          ),
        ),
      ),
    );
  }
}
