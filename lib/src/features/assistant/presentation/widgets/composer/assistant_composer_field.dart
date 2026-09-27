import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_text_direction.dart';
import 'assistant_composer_hint.dart';

/// The growing text field (1–5 lines, then it scrolls). It writes in the
/// direction of what is typed — Arabic in an English app reads right to
/// left — and falls back to the app's direction while empty, where it shows
/// rotating example questions.
class AssistantComposerField extends StatelessWidget {
  const AssistantComposerField({
    super.key,
    required this.controller,
    this.focusNode,
  });

  final TextEditingController controller;

  /// The composer's, so heard words can come back to a focused field.
  final FocusNode? focusNode;

  static const int _maxLines = 5;

  @override
  Widget build(BuildContext context) {
    final rtl = AssistantTextDirection.isRtl(controller.text);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sheet),
      borderSide: const BorderSide(color: AppColors.divider),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: _maxLines,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      textDirection: rtl == null
          ? null
          : (rtl ? TextDirection.rtl : TextDirection.ltr),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
      decoration: InputDecoration(
        // Cycles through example questions while the field is empty.
        hint: const AssistantComposerHint(),
        isDense: true,
        filled: true,
        fillColor: AppColors.smallBackground,
        constraints: const BoxConstraints(minHeight: AppSize.s48),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s14,
          vertical: AppSpacing.s12,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
