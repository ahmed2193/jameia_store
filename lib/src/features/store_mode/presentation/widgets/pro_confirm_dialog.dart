import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// "Are you sure?" before a money-related Pro action. Pops with `true` when
/// confirmed.
class ProConfirmDialog extends StatelessWidget {
  const ProConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      title: Text(
        title,
        style: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => context.pop(true),
          child: Text(
            confirmLabel,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDestructive ? AppColors.error : AppColors.primaryDark,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ),
      ],
    );
  }
}
