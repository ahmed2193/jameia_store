import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/otp_verify_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/utils/failure_message.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../widgets/login/login_body.dart';

/// Jameia `passport_login`: phone entry → `POST /v1/auth/send-otp` → the OTP
/// screen.
///
/// [sessionExpired] arrives as the route extra (set by the app root when the
/// network layer gave up refreshing) rather than from `AuthSessionCubit`, so
/// this page stays independent of the app-global providers (router tests pump
/// it alone) and the notice is scoped to that one navigation.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  void _onStatus(BuildContext context, LoginState state) {
    switch (state.status) {
      case LoginStatus.codeSent:
        final challenge = state.challenge;
        if (challenge == null) return;
        context.push(
          Routes.otpVerify,
          extra: OtpVerifyArgs(
            phone: challenge.phone,
            debugCode: challenge.debugCode,
          ),
        );
      case LoginStatus.error:
        showJameiaSnackBar(
          context,
          state.failure?.localizedMessage ?? 'core.something_went_wrong'.tr(),
        );
      case LoginStatus.initial:
      case LoginStatus.sending:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onStatus,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: ContentClamp(
              child: LoginBody(sessionExpired: sessionExpired),
            ),
          ),
        ),
      ),
    );
  }
}
