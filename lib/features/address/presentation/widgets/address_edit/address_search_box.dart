import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Live search field — `autocomplete(query)` typeahead (RE §3.2 step 3).
class AddressSearchBox extends StatelessWidget {
  const AddressSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            KeetaIcons.search,
            size: 18,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryText,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'addr.search_hint'.tr(),
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
