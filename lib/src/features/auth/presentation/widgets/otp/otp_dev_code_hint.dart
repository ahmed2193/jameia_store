import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import '../auth_link_button.dart';

/// Non-production backends echo the OTP in the send response; show it as a
/// tap-to-fill hint so testers skip the SMS. Renders nothing otherwise.
class OtpDevCodeHint extends StatelessWidget {
  const OtpDevCodeHint({super.key, required this.onUseCode});

  final ValueChanged<String> onUseCode;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpCubit, OtpState, String?>(
      selector: (state) => state.hasDebugCode ? state.debugCode : null,
      builder: (context, code) {
        if (code == null) return const SizedBox.shrink();
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: AuthLinkButton(
            label: 'auth.otp_dev_code'.tr(namedArgs: {'code': code}),
            onPressed: () => onUseCode(code),
            style: AppTextStyles.captionLarge,
          ),
        );
      },
    );
  }
}
