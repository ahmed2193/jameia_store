import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../cubit/address_edit_cubit.dart';
import 'address_form_labels.dart';
import 'boxed_field.dart';
import 'phone_field.dart';
import 'section_header.dart';

/// Contact — name + phone (+965 country chip).
class ContactSection extends StatefulWidget {
  const ContactSection({
    super.key,
    required this.errors,
    required this.onClearError,
  });

  final Map<AddrField, String> errors;
  final ValueChanged<AddrField> onClearError;

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  late final TextEditingController _recipient;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final s = context.read<AddressEditCubit>().state;
    _recipient = TextEditingController(text: s.recipient);
    _phone = TextEditingController(text: s.phone);
  }

  @override
  void dispose() {
    _recipient.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddressEditCubit>();
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
            child: Column(
              children: [
                BoxedField(
                  controller: _recipient,
                  hint: fieldLabel(AddrField.recipient),
                  errorText: widget.errors[AddrField.recipient]?.tr(),
                  onChanged: (v) {
                    cubit.setField(AddrField.recipient, v);
                    widget.onClearError(AddrField.recipient);
                  },
                ),
                const SizedBox(height: AppSpacing.s10),
                PhoneField(
                  controller: _phone,
                  errorText: widget.errors[AddrField.phone]?.tr(),
                  onChanged: (v) {
                    cubit.setField(AddrField.phone, v);
                    widget.onClearError(AddrField.phone);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
