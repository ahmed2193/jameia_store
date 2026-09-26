import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';
import '../auth_submit_button.dart';

/// Primary Continue CTA — enabled once the phone is valid, the loader while
/// the code is being sent. A tap while it is disabled reports [onBlocked] so
/// the page can point at the number.
class LoginContinueButton extends StatelessWidget {
  const LoginContinueButton({super.key, required this.onBlocked});

  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.canContinue != current.canContinue ||
          previous.isSending != current.isSending,
      builder: (context, state) => AuthSubmitButton(
        label: 'auth.continue_btn'.tr(),
        enabled: state.canContinue,
        loading: state.isSending,
        onPressed: context.read<LoginCubit>().submit,
        onBlocked: onBlocked,
      ),
    );
  }
}
