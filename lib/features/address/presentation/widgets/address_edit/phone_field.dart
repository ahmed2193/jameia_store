import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Phone input with a leading "+965 ▾" country-code chip + inline error.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.errorText,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  // Localized inline error message (already `.tr()`-resolved), or null.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.s12,
                  end: AppSpacing.s8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+965',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    const Icon(
                      KeetaIcons.arrowDown,
                      size: 14,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.s12,
                    end: AppSpacing.s12,
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'addr.field.phone'.tr(),
                      hintStyle: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.s6,
              start: AppSpacing.s12,
            ),
            child: Text(
              errorText!,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }
}
