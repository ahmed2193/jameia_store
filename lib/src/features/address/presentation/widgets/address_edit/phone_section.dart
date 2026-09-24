import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/address_field.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'address_form_labels.dart';
import 'phone_field.dart';
import 'section_header.dart';

/// Contact — the courier's phone (+965 chip + 8 local digits).
class PhoneSection extends StatefulWidget {
  const PhoneSection({super.key});

  @override
  State<PhoneSection> createState() => _PhoneSectionState();
}

class _PhoneSectionState extends State<PhoneSection> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<AddressEditCubit>().state.draft.phone,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'addr.contact'.tr(), required: true),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: AppSpacing.s14,
            ),
            child:
                BlocSelector<
                  AddressEditCubit,
                  AddressEditState,
                  AddressFieldError?
                >(
                  selector: (state) => state.errorFor(AddressField.phone),
                  builder: (context, error) => PhoneField(
                    controller: _controller,
                    errorText: addressFieldErrorText(AddressField.phone, error),
                    onChanged: (value) => context
                        .read<AddressEditCubit>()
                        .fieldChanged(AddressField.phone, value),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
