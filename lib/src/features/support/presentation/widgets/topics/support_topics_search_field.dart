import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';

/// Search field of the help topics, with a clear button while [query] has
/// text.
class SupportTopicsSearchField extends StatelessWidget {
  const SupportTopicsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.query,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueNotifier<String> query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Container(
        height: AppSize.s44,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(
              HeroIcons.search,
              size: AppSize.s18,
              color: AppColors.tertiaryText,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyLarge,
                cursorColor: AppColors.primaryText,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'support.search_help_topics'.tr(),
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<String>(
              valueListenable: query,
              builder: (_, value, _) {
                if (value.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(start: AppSpacing.s8),
                    child: Icon(
                      HeroIcons.searchClear,
                      size: AppSize.s16,
                      color: AppColors.tertiaryText,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
