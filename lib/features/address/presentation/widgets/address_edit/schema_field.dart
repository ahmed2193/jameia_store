import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/keeta_geocode.dart';
import '../../cubit/address_edit_cubit.dart';
import 'address_form_labels.dart';
import 'boxed_field.dart';

/// One schema field bound to the cubit by its [AddrField].
class SchemaField extends StatefulWidget {
  const SchemaField({
    super.key,
    required this.spec,
    this.errorKey,
    required this.onClearError,
  });
  final AddressFieldSpec spec;
  // i18n KEY of this field's inline error, or null when valid.
  final String? errorKey;
  final VoidCallback onClearError;

  @override
  State<SchemaField> createState() => _SchemaFieldState();
}

class _SchemaFieldState extends State<SchemaField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final v = context.read<AddressEditCubit>().state.fieldValue(
      widget.spec.field,
    );
    _ctrl = TextEditingController(text: v);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoxedField(
      controller: _ctrl,
      hint: fieldLabel(widget.spec.field),
      maxLength: widget.spec.maxLength,
      errorText: widget.errorKey?.tr(),
      onChanged: (v) {
        context.read<AddressEditCubit>().setField(widget.spec.field, v);
        widget.onClearError();
      },
    );
  }
}
