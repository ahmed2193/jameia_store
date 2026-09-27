import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/otp_verify_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/spring_curve.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../cubit/auth_session_cubit.dart';
import '../cubit/otp_cubit.dart';
import '../cubit/otp_state.dart';
import '../widgets/otp/otp_app_bar.dart';
import '../widgets/otp/otp_body.dart';

/// Code entry: `POST /v1/auth/verify-otp`. On success the app-global
/// [AuthSessionCubit] learns the customer at once, the check shows for
/// [AppSprings.successHold], then the whole stack is replaced by the shell —
/// every page cubit is rebuilt for the new session — and the page that asked
/// for the sign-in ([OtpVerifyArgs.returnTo]) opens again on top of it. A
/// refused code is explained under the digits (and felt); any other failure
/// is a snack bar.
class OtpVerifyPage extends StatelessWidget {
  const OtpVerifyPage({super.key, required this.args});

  final OtpVerifyArgs args;

  void _enterApp(BuildContext context) {
    final router = GoRouter.of(context);
    router.go(Routes.shell);
    final returnTo = args.returnTo;
    if (returnTo == null) return;
    // Once the shell is the whole stack, so "back" from the page lands home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.push<void>(returnTo);
    });
  }

  void _onStatus(BuildContext context, OtpState state) {
    switch (state.status) {
      case OtpStatus.verified:
        final customer = state.customer;
        if (customer != null) {
          context.read<AuthSessionCubit>().signedIn(customer);
        }
        Haptics.success();
        Future<void>.delayed(AppSprings.successHold, () {
          if (context.mounted) _enterApp(context);
        });
      case OtpStatus.error:
        if (state.failureIsRefusal) {
          Haptics.warning();
          return;
        }
        final failure = state.failure;
        if (failure == null) {
          showJameiaSnackBar(context, 'core.something_went_wrong'.tr());
        } else {
          // Checking the code: offline it says so, the code stays typed.
          showFailureSnackBar(context, failure, action: true);
        }
      case OtpStatus.idle:
      case OtpStatus.verifying:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OtpCubit>(param1: args.phone, param2: args.debugCode),
      child: BlocListener<OtpCubit, OtpState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onStatus,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: const OtpAppBar(),
          body: SafeArea(
            top: false,
            child: ContentClamp(child: OtpBody(phone: args.phone)),
          ),
        ),
      ),
    );
  }
}
