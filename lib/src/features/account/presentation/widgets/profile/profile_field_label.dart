import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Caption above a profile form field.
class ProfileFieldLabel extends StatelessWidget {
  const ProfileFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s6),
    child: Text(
      text,
      style: AppTextStyles.captionLarge.copyWith(
        color: AppColors.secondaryText,
      ),
    ),
  );
}
