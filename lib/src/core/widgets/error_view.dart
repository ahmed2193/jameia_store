import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'app_outline_button.dart';

/// Error-state placeholder with retry.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PopScale.onMount(
              child: Icon(
                Icons.error_outline_rounded,
                size: AppSize.s56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              message ?? 'core.something_went_wrong'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppOutlineButton(label: 'retry'.tr(), onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
