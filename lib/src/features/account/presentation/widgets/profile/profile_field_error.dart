import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Inline validation line under a profile field; collapses when [message] is
/// null so the layout never jumps.
class ProfileFieldError extends StatelessWidget {
  const ProfileFieldError({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.s4,
        start: AppSpacing.s2,
      ),
      child: Text(
        text,
        style: AppTextStyles.captionLarge.copyWith(color: AppColors.error),
      ),
    );
  }
}
