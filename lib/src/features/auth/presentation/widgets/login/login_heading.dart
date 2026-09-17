import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "Log in or sign up" title + phone prompt.
class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.log_in_or_sign_up'.tr(),
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          'auth.enter_phone_to_continue'.tr(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
