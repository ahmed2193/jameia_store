import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/otp_verify_args.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/success_beat.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/brand_sheet_scaffold.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../cubit/auth_session_cubit.dart';
import '../cubit/otp_cubit.dart';
import '../cubit/otp_state.dart';
import '../widgets/auth_top_button.dart';
import '../widgets/otp/otp_body.dart';

/// Sign-in, step two: the code — `POST /v1/auth/verify-otp`. The same brand
/// header as the phone step (the route only cross-fades the sheet, so the
/// header stays put), with the code in the sheet. While the code is checked
/// the busy disc holds the screen; once it is accepted the disc draws a
/// check, the app-global [AuthSessionCubit] learns the customer at once and,
/// after the [SuccessBeat], the whole stack is replaced by the shell
/// — every page cubit is rebuilt for the new session — on the tab sign-in
/// was opened from, and the page that asked for it opens again on top
/// ([OtpVerifyArgs.login], [SignInFlow.leave]). A refused code is explained under the digits (and felt); any other
/// failure is a snack bar.
class OtpVerifyPage extends StatelessWidget {
  const OtpVerifyPage({super.key, required this.args});

  final OtpVerifyArgs args;

  static bool _verifying(OtpState state) => state.isVerifying;
  static bool _verified(OtpState state) => state.isVerified;

  /// The check could not be run (a refused code is the digits' to tell:
  /// they shake with the reason under them).
  static bool _failed(OtpState state) =>
      state.status == OtpStatus.error && !state.failureIsRefusal;

  void _onStatus(BuildContext context, OtpState state) {
    switch (state.status) {
      case OtpStatus.verified:
        final customer = state.customer;
        if (customer != null) {
          context.read<AuthSessionCubit>().signedIn(customer);
        }
        Haptics.done();
        unawaited(
          SuccessBeat.hold(context).then((_) {
            if (context.mounted) SignInFlow.leave(context, args.login);
          }),
        );
      case OtpStatus.error:
        if (state.failureIsRefusal) {
          Haptics.refuse();
          return;
        }
        final failure = state.failure;
        if (failure == null) {
          showHeroSnackBar(
            context,
            'core.something_went_wrong'.tr(),
            tone: HeroSnackTone.error,
          );
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
        child: CubitBusyOverlay<OtpCubit, OtpState>(
          busyOf: _verifying,
          doneOf: _verified,
          failOf: _failed,
          doneLabel: 'auth.otp_verified'.tr(),
          child: Scaffold(
            backgroundColor: AppColors.primary,
            body: BrandSheetScaffold(
              logoLabel: AppConstants.appName,
              leading: AuthTopButton(args: args.login),
              rise: false,
              child: ContentClamp(child: OtpBody(phone: args.phone)),
            ),
          ),
        ),
      ),
    );
  }
}
