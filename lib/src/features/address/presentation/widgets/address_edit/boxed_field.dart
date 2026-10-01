import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/hero_input_decoration.dart';

/// A text field of the address form in the app's one field look
/// ([HeroInputDecoration.outlined]: white, 12 dp corners, a hairline, an ink
/// outline while focused, red once refused), the label as the hint. The
/// reason a value is refused is one line under the field, never inside it.
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

  /// A multi-line field opens at this many lines.
  static const int _multiLineMin = 2;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          minLines: maxLines > 1 ? _multiLineMin : 1,
          maxLength: maxLength,
          style: AppTextStyles.itemTitle,
          cursorColor: AppColors.primaryText,
          decoration: HeroInputDecoration.outlined(
            hintText: hint,
            counterText: '',
            error: error != null,
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
