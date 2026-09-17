import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/phone_number.dart';
import '../auth_link_button.dart';

/// Title, "we sent a code to [phone]" line and the edit-phone link (pops
/// back to login).
class OtpHeader extends StatelessWidget {
  const OtpHeader({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.otp_title'.tr(),
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          'auth.otp_sent_to'.tr(namedArgs: {'phone': phone.display}),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AuthLinkButton(
            label: 'auth.otp_edit_phone'.tr(),
            onPressed: context.pop,
          ),
        ),
      ],
    );
  }
}
