import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// Primary Continue CTA — enabled once the phone is valid, spinning while the
/// code is being sent.
class LoginContinueButton extends StatelessWidget {
  const LoginContinueButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          previous.canContinue != current.canContinue ||
          previous.isSending != current.isSending,
      builder: (context, state) => AppButton(
        label: 'auth.continue_btn'.tr(),
        enabled: state.canContinue,
        loading: state.isSending,
        onPressed: context.read<LoginCubit>().submit,
      ),
    );
  }
}
