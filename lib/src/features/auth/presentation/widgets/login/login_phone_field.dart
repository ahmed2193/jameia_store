import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/ascii_digits_formatter.dart';
import '../../../domain/entities/phone_number.dart';
import 'login_dial_code.dart';
import 'login_phone_error.dart';
import 'login_phone_outline.dart';
import 'login_phone_valid_mark.dart';

/// The phone unit: `+965` and the number in ONE outline, always laid out
/// left-to-right (a phone number reads the same in Arabic), with the
/// validation line below in the page's own direction. Digits from an Arabic
/// keyboard are kept (as ASCII) and a pasted / autofilled `+965` or `00965`
/// is dropped as it arrives ([PhoneNumber.localDigitsOf]). A new [nudges]
/// value shakes the unit (a tap on the disabled Continue).
class LoginPhoneField extends StatelessWidget {
  const LoginPhoneField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorRevealed,
    required this.nudges,
    required this.onSubmitted,
  });

  static const double _tracking = AppSize.s1;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> errorRevealed;
  final ValueListenable<int> nudges;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final digits = AppTextStyles.headingLarge.copyWith(
      fontWeight: AppTextStyles.bold,
      letterSpacing: _tracking,
      fontFeatures: _tabular,
    );
    final unit = Directionality(
      textDirection: TextDirection.ltr,
      child: LoginPhoneOutline(
        focusNode: focusNode,
        errorRevealed: errorRevealed,
        child: Row(
          children: [
            const LoginDialCode(),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmitted(),
                autofillHints: const [
                  AutofillHints.telephoneNumber,
                  AutofillHints.telephoneNumberNational,
                ],
                inputFormatters: const [
                  AsciiDigitsFormatter(normalize: PhoneNumber.localDigitsOf),
                ],
                style: digits,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'auth.phone_number_hint'.tr(),
                  // Smaller than the digits so it fits beside the chip at
                  // a large text size.
                  hintStyle: AppTextStyles.subheadingMedium.copyWith(
                    color: AppColors.tertiaryText,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            const LoginPhoneValidMark(),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: nudges,
          child: unit,
          builder: (context, count, child) => ShakeX(
            shakeKey: count,
            amplitude: AppSize.s8,
            cycles: 3,
            child: child!,
          ),
        ),
        LoginPhoneError(revealed: errorRevealed),
      ],
    );
  }
}
