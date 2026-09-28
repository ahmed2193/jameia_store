import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// "Continue as guest": a plain text link under the ways in. Back to the
/// page that opened sign-in when there is one; otherwise into the shell with
/// `go`, so its cubits start fresh for a guest.
class LoginGuestButton extends StatelessWidget {
  const LoginGuestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Routes.shell),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryText,
          minimumSize: const Size(0, AppSize.s48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
        ),
        child: Text(
          'auth.continue_as_guest'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
