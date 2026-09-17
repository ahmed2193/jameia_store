import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// Bordered rounded input field (~52dp) with the label rendered as the hint.
class BoxedField extends StatelessWidget {
  const BoxedField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  // Localized inline error message (already `.tr()`-resolved), or null.
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Container(
      constraints: BoxConstraints(minHeight: maxLines > 1 ? 80 : 52),
      alignment: Alignment.center,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.divider,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        minLines: 1,
        maxLength: maxLength,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          border: InputBorder.none,
          // Hide the default error border (the box border above turns red);
          // Flutter still renders the red error message beneath the field.
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorText: errorText,
          errorStyle: AppTextStyles.captionLarge.copyWith(
            color: AppColors.error,
          ),
          hintText: hint,
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ),
    );
  }
}
