import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/phone_number.dart';
import '../../../../../core/widgets/jameia_outlined_field.dart';
import 'login_country_code_box.dart';
import 'login_phone_error.dart';

/// Phone field: the `+965` box and the number input side by side, with the
/// inline validation line below.
class LoginPhoneField extends StatelessWidget {
  const LoginPhoneField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const LoginCountryCodeBox(),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: JameiaOutlinedField(
                controller: controller,
                hintText: 'auth.phone_number_hint'.tr(),
                maxLength: PhoneNumber.kuwaitLocalLength,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.telephoneNumberNational],
              ),
            ),
          ],
        ),
        const LoginPhoneError(),
      ],
    );
  }
}
