import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import '../auth_submit_button.dart';

/// Primary Verify CTA — enabled once the code is complete, the loader while
/// the backend checks it, a check once it is accepted (the page moves on a
/// beat later).
class OtpVerifyButton extends StatelessWidget {
  const OtpVerifyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      buildWhen: (previous, current) =>
          previous.canVerify != current.canVerify ||
          previous.isVerifying != current.isVerifying ||
          previous.isVerified != current.isVerified,
      builder: (context, state) => AuthSubmitButton(
        label: 'auth.otp_verify_btn'.tr(),
        enabled: state.canVerify,
        loading: state.isVerifying,
        success: state.isVerified,
        successLabel: 'auth.otp_verified'.tr(),
        onPressed: context.read<OtpCubit>().verify,
      ),
    );
  }
}
