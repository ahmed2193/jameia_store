import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/jameia_input_decoration.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section.dart';

/// Optional note for the store, capped at the API's 256 characters. The field
/// owns its text (the controller); each keystroke only records it in the
/// draft, so nothing else on the page rebuilds while typing.
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
    return CheckoutSection(
      title: 'checkout.notes_title'.tr(),
      child: TextField(
        controller: _controller,
        maxLength: CheckoutDraft.maxNotesLength,
        maxLines: _lines,
        textInputAction: TextInputAction.done,
        onChanged: (notes) => context.read<CheckoutCubit>().setNotes(notes),
        style: AppTextStyles.itemTitle,
        cursorColor: AppColors.primaryText,
        decoration: JameiaInputDecoration.outlined(
          hintText: 'checkout.notes_hint'.tr(),
        ),
      ),
    );
  }
}
