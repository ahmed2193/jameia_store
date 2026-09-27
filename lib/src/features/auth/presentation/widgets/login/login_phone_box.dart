import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/ascii_digits_formatter.dart';
import '../../../../../core/widgets/labeled_field_box.dart';
import '../../../domain/entities/phone_number.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';
import 'login_phone_valid_mark.dart';

/// The "Phone number" box: the local digits in one field, always left to
/// right (a phone number reads the same in Arabic), with the green check at
/// its end once the number is valid. Digits from an Arabic keyboard are kept
/// (as ASCII) and a pasted / autofilled `+965` or `00965` is dropped as it
/// arrives ([PhoneNumber.localDigitsOf]). Only the box's ring follows focus
/// and the revealed error — the field itself never rebuilds for them.
class LoginPhoneBox extends StatelessWidget {
  const LoginPhoneBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorRevealed,
    required this.onSubmitted,
  });

  static const double _tracking = AppSize.s1;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> errorRevealed;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final field = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
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
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: AppTextStyles.bold,
                  letterSpacing: _tracking,
                  fontFeatures: _tabular,
                ),
                cursorColor: AppColors.primaryDark,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'auth.phone_digits_hint'.tr(),
                  hintStyle: AppTextStyles.subheadingLarge.copyWith(
                    color: AppColors.tertiaryText,
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
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.phone.isValid,
      builder: (context, valid) => ListenableBuilder(
        listenable: Listenable.merge([focusNode, errorRevealed]),
        child: field,
        builder: (context, child) => LabeledFieldBox(
          label: 'auth.phone_label'.tr(),
          focused: focusNode.hasFocus,
          error: errorRevealed.value && !valid,
          onTap: focusNode.requestFocus,
          child: Center(child: child),
        ),
      ),
    );
  }
}
