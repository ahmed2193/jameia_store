import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "Welcome" and the one thing the page asks for — the phone number —
/// centred under the offer card.
class LoginWelcomeHeading extends StatelessWidget {
  const LoginWelcomeHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            'auth.welcome_title'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'auth.welcome_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.subheadingLarge.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
