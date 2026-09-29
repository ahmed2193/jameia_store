import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/hero_submit_button.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';

/// Primary Verify CTA. Grey until the code is complete, then the green wipes
/// in once; it holds that green (no taps) while the code is checked and once
/// it is accepted — the page's busy disc is the one loader, and its check
/// the success. A tap while it is grey reports [onBlocked] so the page can
/// point at the code (the same "no" as login's Continue).
class OtpVerifyButton extends StatelessWidget {
  const OtpVerifyButton({super.key, required this.onBlocked});

  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      buildWhen: (previous, current) =>
          previous.canVerify != current.canVerify ||
          previous.isLocked != current.isLocked,
      builder: (context, state) => HeroSubmitButton(
        label: 'auth.otp_verify_btn'.tr(),
        enabled: state.canVerify,
        holding: state.isLocked,
        readyFlourish: true,
        onPressed: context.read<OtpCubit>().verify,
        onBlocked: onBlocked,
      ),
    );
  }
}
