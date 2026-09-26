import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import 'search_clear_button.dart';

/// The pill search box (docs/design_system.md: muted fill, pill radius,
/// 48 dp): a magnifier, the text and — while there is text — a clear ✕. It
/// opens focused (the screen is reached by tapping a search entry) and the
/// keyboard's search key commits the text.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  static const double height = AppSize.s48;

  static const OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
    borderSide: BorderSide.none,
  );

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        onSubmitted: onSubmit,
        style: AppTextStyles.itemTitle,
        cursorColor: AppColors.primaryText,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.smallBackground,
          hintText: 'search.store_hint'.tr(),
          hintMaxLines: 1,
          hintStyle: AppTextStyles.itemTitle.copyWith(
            color: AppColors.secondaryText,
          ),
          contentPadding: EdgeInsets.zero,
          border: _border,
          enabledBorder: _border,
          focusedBorder: _border,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: AppSize.s24,
            color: AppColors.primaryText,
          ),
          suffixIcon: SearchClearButton(
            controller: controller,
            onClear: onClear,
          ),
        ),
      ),
    );
  }
}
