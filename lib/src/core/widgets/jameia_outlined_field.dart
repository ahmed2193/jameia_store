import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';
import 'jameia_outlined_box.dart';

/// A text input inside a [JameiaOutlinedBox] with the shared collapsed
/// decoration (no counter, no Material border, muted hint). Pass
/// [inputFormatters] for digits-only fields (phone, OTP).
class JameiaOutlinedField extends StatelessWidget {
  const JameiaOutlinedField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLength,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.textAlign = TextAlign.start,
    this.style,
    this.hintStyle,
    this.height = AppSize.s45,
    this.error = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextAlign textAlign;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final double height;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return JameiaOutlinedBox(
      height: height,
      error: error,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        textAlign: textAlign,
        style: style ?? AppTextStyles.headingSmall,
        decoration: InputDecoration(
          counterText: '',
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s14,
          ),
          hintText: hintText,
          hintStyle:
              hintStyle ??
              AppTextStyles.headingSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
        ),
      ),
    );
  }
}
