import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/hero_submit_button.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// Primary Continue CTA. Grey until the number is valid, then the green
/// wipes in once; it holds that green (no taps) while the code is on its
/// way — the page's busy disc is the one loader on screen. A tap while it is
/// disabled reports [onBlocked] so the page can point at the number.
class LoginContinueButton extends StatelessWidget {
  const LoginContinueButton({super.key, required this.onBlocked});

  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.canContinue != current.canContinue ||
          previous.isSending != current.isSending,
      builder: (context, state) => HeroSubmitButton(
        label: 'auth.continue_btn'.tr(),
        enabled: state.canContinue,
        holding: state.isSending,
        readyFlourish: true,
        onPressed: context.read<LoginCubit>().submit,
        onBlocked: onBlocked,
      ),
    );
  }
}
