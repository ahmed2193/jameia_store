import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';

/// Primary Verify CTA — enabled once the code is complete, spinning while the
/// backend checks it.
class OtpVerifyButton extends StatelessWidget {
  const OtpVerifyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      buildWhen: (previous, current) =>
          previous.canVerify != current.canVerify ||
          previous.isVerifying != current.isVerifying,
      builder: (context, state) => AppButton(
        label: 'auth.otp_verify_btn'.tr(),
        enabled: state.canVerify,
        loading: state.isVerifying,
        onPressed: context.read<OtpCubit>().verify,
      ),
    );
  }
}
