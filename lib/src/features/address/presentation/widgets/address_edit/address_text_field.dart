import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/address_draft.dart';
import '../../../domain/entities/address_field.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'address_form_labels.dart';
import 'boxed_field.dart';

/// One free-text address field bound to the form by its [field]. The text is
/// seeded once from the draft; only this field's error rebuilds it.
class AddressTextField extends StatefulWidget {
  const AddressTextField({super.key, required this.field, this.maxLines = 1});

  final AddressField field;
  final int maxLines;

  @override
  State<AddressTextField> createState() => _AddressTextFieldState();
}

class _AddressTextFieldState extends State<AddressTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<AddressEditCubit>().state.draft.valueOf(widget.field),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressEditCubit, AddressEditState, AddressFieldError?>(
      selector: (state) => state.errorFor(widget.field),
      builder: (context, error) => BoxedField(
        controller: _controller,
        hint: addressFieldHint(widget.field),
        maxLines: widget.maxLines,
        maxLength: AddressDraft.maxLengthOf(widget.field),
        errorText: addressFieldErrorText(widget.field, error),
        onChanged: (value) =>
            context.read<AddressEditCubit>().fieldChanged(widget.field, value),
      ),
    );
  }
}
