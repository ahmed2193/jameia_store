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
import '../cubit/auth_session_cubit.dart';
import '../cubit/otp_cubit.dart';
import '../cubit/otp_state.dart';
import '../widgets/otp/otp_body.dart';

/// Code entry: `POST /v1/auth/verify-otp`. On success the app-global
/// [AuthSessionCubit] learns the customer and the whole stack is replaced by
/// the shell.
class OtpVerifyPage extends StatelessWidget {
  const OtpVerifyPage({super.key, required this.args});

  final OtpVerifyArgs args;

  void _onStatus(BuildContext context, OtpState state) {
    switch (state.status) {
      case OtpStatus.verified:
        final customer = state.customer;
        if (customer != null) {
          context.read<AuthSessionCubit>().signedIn(customer);
        }
        context.go(Routes.shell);
      case OtpStatus.error:
        showJameiaSnackBar(
          context,
          state.failure?.localizedMessage ?? 'core.something_went_wrong'.tr(),
        );
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
          appBar: AppBar(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
          ),
          body: SafeArea(
            child: ContentClamp(child: OtpBody(phone: args.phone)),
          ),
        ),
      ),
    );
  }
}
