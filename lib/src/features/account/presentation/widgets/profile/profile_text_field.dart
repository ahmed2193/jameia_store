import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import 'profile_field_error.dart';
import 'profile_field_label.dart';
import 'profile_field_shell.dart';

/// One labelled text input of the profile form: the caption, the filled
/// shell (its border follows the focus without rebuilding the text field),
/// the inline error and a short shake whenever [shakeKey] changes (a save
/// refused because of this field).
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.hintText,
    required this.maxLength,
    required this.onChanged,
    required this.shakeKey,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofillHints,
  });

  static const int _shakeCycles = 3;

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String hintText;
  final int maxLength;
  final ValueChanged<String> onChanged;

  /// A new value shakes the field (0 = never refused yet).
  final int shakeKey;

  /// Shown under the field (and paints it red) when set.
  final String? errorText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      autofillHints: autofillHints,
      onChanged: onChanged,
      style: AppTextStyles.headingSmall,
      cursorColor: AppColors.primaryDark,
      decoration: InputDecoration(
        counterText: '',
        isCollapsed: true,
        border: InputBorder.none,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s14,
        ),
        hintText: hintText,
        hintStyle: AppTextStyles.headingSmall.copyWith(
          color: AppColors.tertiaryText,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldLabel(label),
        ShakeX(
          shakeKey: shakeKey,
          amplitude: AppSize.s8,
          cycles: _shakeCycles,
          child: RepaintBoundary(
            child: ListenableBuilder(
              listenable: focusNode,
              builder: (context, input) => ProfileFieldShell(
                focused: focusNode.hasFocus,
                error: hasError,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s14,
                ),
                child: input!,
              ),
              child: Row(
                children: [
                  HeroIcon(
                    icon,
                    size: AppSize.s20,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(child: field),
                ],
              ),
            ),
          ),
        ),
        ProfileFieldError(message: errorText),
      ],
    );
  }
}
