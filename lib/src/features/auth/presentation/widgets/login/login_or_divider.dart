import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// Centered "or" divider between phone and social sign-in.
class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: ThinDivider()),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
          ),
          child: Text(
            'auth.or'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ),
        const Expanded(child: ThinDivider()),
      ],
    );
  }
}
