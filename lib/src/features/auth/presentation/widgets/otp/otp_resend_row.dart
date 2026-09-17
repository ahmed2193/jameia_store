import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import '../auth_link_button.dart';

/// "Resend code in 45s" countdown that turns into a Resend link (disabled
/// while a verify is in flight), with a small spinner while resending.
class OtpResendRow extends StatelessWidget {
  const OtpResendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      buildWhen: (previous, current) =>
          previous.resendSecondsLeft != current.resendSecondsLeft ||
          previous.isResending != current.isResending ||
          previous.canResend != current.canResend,
      builder: (context, state) {
        if (state.isResending) {
          return const Center(
            child: SizedBox(
              width: AppSize.s16,
              height: AppSize.s16,
              child: CircularProgressIndicator(strokeWidth: AppSize.s2),
            ),
          );
        }
        if (state.isCooldownOver) {
          return Center(
            child: AuthLinkButton(
              label: 'auth.otp_resend'.tr(),
              onPressed: state.canResend
                  ? context.read<OtpCubit>().resend
                  : null,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s8,
          ),
          child: Text(
            'auth.otp_resend_in'.tr(
              namedArgs: {'seconds': state.resendSecondsLeft.toString()},
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        );
      },
    );
  }
}
