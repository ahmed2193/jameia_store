import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/otp_verify_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/brand_sheet_scaffold.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../widgets/auth_top_button.dart';
import '../widgets/login/login_body.dart';

/// Sign-in, step one: phone entry → `POST /v1/auth/send-otp` → the code
/// step. The brand sheet page: the living green header with the Hero logo,
/// and the sheet rising with the store's welcome offer, "Welcome" and the
/// number (plus `GET /v1/init` for that offer).
///
/// [sessionExpired] arrives as the route extra (set by the app root when the
/// network layer gave up refreshing) rather than from `AuthSessionCubit`, so
/// this page stays independent of the app-global providers (router tests pump
/// it alone) and the notice is scoped to that one navigation. [returnTo]
/// (from `LoginArgs`) travels on to the code step, which reopens that page
/// once the customer is signed in.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.sessionExpired = false, this.returnTo});

  final bool sessionExpired;
  final String? returnTo;

  static bool _sending(LoginState state) => state.isSending;

  /// The code could not be asked for: the busy disc's × (docs/motion B3-05).
  static bool _failed(LoginState state) => state.status == LoginStatus.error;

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
            returnTo: returnTo,
          ),
        );
      case LoginStatus.error:
        final failure = state.failure;
        if (failure == null) {
          showHeroSnackBar(
            context,
            'core.something_went_wrong'.tr(),
            tone: HeroSnackTone.error,
          );
        } else {
          // Asking for a code: offline it says so, the number stays typed.
          showFailureSnackBar(context, failure, action: true);
        }
      case LoginStatus.initial:
      case LoginStatus.sending:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>()..loadWelcomeBonus(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<LoginCubit, LoginState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: _onStatus,
          ),
        ],
        child: CubitBusyOverlay<LoginCubit, LoginState>(
          busyOf: _sending,
          failOf: _failed,
          child: Scaffold(
            backgroundColor: AppColors.primary,
            body: BrandSheetScaffold(
              logoLabel: AppConstants.appName,
              leading: const AuthTopButton(),
              child: ContentClamp(
                child: LoginBody(sessionExpired: sessionExpired),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
