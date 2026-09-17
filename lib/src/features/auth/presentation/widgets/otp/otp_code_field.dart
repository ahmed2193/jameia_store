import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/otp_challenge.dart';
import '../../../../../core/widgets/jameia_outlined_field.dart';

/// Single digits-only code input (the backend accepts 4–8 characters, so one
/// field beats a fixed number of boxes). Autofills from the SMS on both OSes.
/// Focus is owned by the body, which requests it once the route settles.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Wide tracking so the digits read as a code, not a number.
  static const double _letterSpacing = 8;

  @override
  Widget build(BuildContext context) {
    return JameiaOutlinedField(
      controller: controller,
      focusNode: focusNode,
      hintText: 'auth.otp_code_hint'.tr(),
      maxLength: OtpChallenge.maxCodeLength,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      height: AppSize.s55,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      textAlign: TextAlign.center,
      style: AppTextStyles.displayMedium.copyWith(
        fontWeight: AppTextStyles.bold,
        letterSpacing: _letterSpacing,
      ),
      // The hint inherits the input style, so undo the wide tracking.
      hintStyle: AppTextStyles.headingSmall.copyWith(
        color: AppColors.tertiaryText,
        letterSpacing: 0,
      ),
    );
  }
}
