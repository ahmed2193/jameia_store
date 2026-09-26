import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/utils/ascii_digits_formatter.dart';
import '../../../domain/entities/otp_challenge.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';

/// The real field under the painted slots: transparent text, no caret, no
/// selection paint (the slots show all of that), digits only — Arabic-Indic
/// digits included — capped at [OtpChallenge.maxCodeLength]. It keeps focus
/// and the keyboard while the code is checked (edits are frozen instead of
/// the field going read-only), and turns read-only once the code is accepted
/// so the keyboard steps aside for the success moment.
class OtpCodeInput extends StatelessWidget {
  const OtpCodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  static const TextStyle _invisible = TextStyle(
    color: AppColors.scrimTransparent,
  );
  static const AsciiDigitsFormatter _digits = AsciiDigitsFormatter(
    maxLength: OtpChallenge.maxCodeLength,
  );

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpCubit, OtpState, (bool, bool)>(
      selector: (state) => (state.isVerifying, state.isVerified),
      builder: (context, lock) {
        final (verifying, verified) = lock;
        return TextSelectionTheme(
          data: const TextSelectionThemeData(
            selectionColor: AppColors.scrimTransparent,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: verified,
            showCursor: false,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              _digits,
              if (verifying)
                TextInputFormatter.withFunction((previous, _) => previous),
            ],
            onSubmitted: (_) => context.read<OtpCubit>().verify(),
            style: _invisible,
            decoration: InputDecoration.collapsed(
              hintText: 'auth.otp_code_hint'.tr(),
              hintStyle: _invisible,
            ),
          ),
        );
      },
    );
  }
}
