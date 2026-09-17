import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Explains why the user landed on login after the session could not be
/// refreshed (shown when the route was opened with the expired flag).
class LoginExpiredBanner extends StatelessWidget {
  const LoginExpiredBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.error,
            size: AppSize.s18,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'auth.session_expired'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
