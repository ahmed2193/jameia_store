import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section_title.dart';

/// Optional note for the store, capped at the API's 256 characters.
class CheckoutNotesField extends StatefulWidget {
  const CheckoutNotesField({super.key});

  @override
  State<CheckoutNotesField> createState() => _CheckoutNotesFieldState();
}

class _CheckoutNotesFieldState extends State<CheckoutNotesField> {
  late final TextEditingController _controller;

  static const int _lines = 3;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<CheckoutCubit>().state.draft.notes,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle('checkout.notes_title'.tr()),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: TextField(
            controller: _controller,
            maxLength: CheckoutDraft.maxNotesLength,
            maxLines: _lines,
            textInputAction: TextInputAction.done,
            onChanged: context.read<CheckoutCubit>().setNotes,
            decoration: InputDecoration(hintText: 'checkout.notes_hint'.tr()),
          ),
        ),
      ],
    );
  }
}
