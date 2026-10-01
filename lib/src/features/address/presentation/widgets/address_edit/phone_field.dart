import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_field_shell.dart';

/// Phone input in the app's one field look ([HeroFieldShell]): the "+965"
/// country code (Kuwait numbers only, so it is not a picker) behind a
/// hairline, then the number; the reason a number is refused is one line
/// under the field.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  static const String _countryCode = '+965';

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  // Localized inline error message (already `.tr()`-resolved), or null.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroFieldShell(
          error: error != null,
          padding: EdgeInsetsDirectional.zero,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s16,
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(_countryCode, style: AppTextStyles.itemTitle),
                ),
              ),
              const SizedBox(
                width: AppSize.s1,
                height: AppSize.s24,
                child: ColoredBox(color: AppColors.divider),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s12,
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.itemTitle,
                    cursorColor: AppColors.primaryText,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'addr.field.phone'.tr(),
                      hintStyle: AppTextStyles.itemTitle.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.s6,
              start: AppSpacing.s4,
            ),
            child: Text(
              error,
              style: AppTextStyles.meta.copyWith(color: AppColors.errorDeep),
            ),
          ),
      ],
    );
  }
}
