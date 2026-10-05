import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/inline_field_error.dart';
import '../../../../../core/widgets/labeled_field_box.dart';
import '../../../domain/entities/address_field.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'address_form_labels.dart';

/// The frame of one address-form field, in the app's field look: the
/// [label] over a box that rings green while [focus] holds it and red once
/// the [field] is refused, and the reason it is refused under it. [box]
/// lays the [input] out inside the box. Only the field's error and
/// [boxState] (the focus, when not given) rebuild the frame — never the
/// input itself.
class AddressFieldFrame extends StatelessWidget {
  const AddressFieldFrame({
    super.key,
    required this.field,
    required this.label,
    required this.focus,
    this.boxState,
    this.height = AppSize.s56,
    required this.input,
    required this.box,
  });

  final AddressField field;
  final String label;
  final FocusNode focus;
  final Listenable? boxState;
  final double height;
  final Widget input;
  final TransitionBuilder box;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressEditCubit, AddressEditState, AddressFieldError?>(
      selector: (state) => state.errorFor(field),
      builder: (context, error) {
        final message = addressFieldErrorText(field, error);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: boxState ?? focus,
              child: input,
              builder: (context, child) => LabeledFieldBox(
                label: label,
                focused: focus.hasFocus,
                error: message != null,
                onTap: focus.requestFocus,
                height: height,
                child: box(context, child),
              ),
            ),
            InlineFieldError(message: message, announce: false),
          ],
        );
      },
    );
  }
}
