import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/ascii_digits_formatter.dart';
import '../../../domain/entities/address_draft.dart';
import '../../../domain/entities/address_field.dart';
import '../../cubit/address_edit_cubit.dart';
import 'address_field_frame.dart';

/// The courier's number, in the form's field frame: the "+965" code
/// (Kuwait numbers only, so it is not a picker) behind a hairline, then the
/// digits — left to right in both languages, Arabic digits kept as ASCII.
class PhoneField extends StatefulWidget {
  const PhoneField({super.key});

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  static const String _countryCode = '+${AddressDraft.phoneCountryCode}';

  late final TextEditingController _controller = TextEditingController(
    text: context.read<AddressEditCubit>().state.draft.phone,
  );
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = TextField(
      controller: _controller,
      focusNode: _focus,
      onChanged: (value) => context.read<AddressEditCubit>().fieldChanged(
        AddressField.phone,
        value,
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      // A pasted "+965…" / "00965…" keeps only the local digits.
      inputFormatters: const [
        AsciiDigitsFormatter(
          maxLength: AddressDraft.phoneDigits,
          normalize: AddressDraft.localPhone,
        ),
      ],
      style: AppTextStyles.itemTitle,
      cursorColor: AppColors.primaryDark,
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
      ),
    );
    return AddressFieldFrame(
      field: AddressField.phone,
      label: 'addr.field.phone_label'.tr(),
      focus: _focus,
      input: input,
      box: (context, child) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s14,
              ),
              child: Text(_countryCode, style: AppTextStyles.itemTitle),
            ),
            const SizedBox(
              width: AppSize.s1,
              height: AppSize.s24,
              child: ColoredBox(color: AppColors.divider),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s12,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
