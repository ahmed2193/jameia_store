import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/typed_text_direction.dart';
import '../../../domain/entities/address_draft.dart';
import '../../../domain/entities/address_field.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'address_field_clear_button.dart';
import 'address_field_frame.dart';

/// One address field bound to the form by its [field], in the form's field
/// frame ([AddressFieldFrame]): a ⊗ empties it while it is focused and
/// holds text. The text is seeded from the draft, follows it when the draft
/// changes under the field (the map read the pin after the form came up),
/// and reads in its own direction ([TypedTextDirection]); the box rebuilds
/// on focus and on emptying / filling, never per keystroke.
class AddressTextField extends StatefulWidget {
  const AddressTextField({
    super.key,
    required this.field,
    required this.label,
    this.hint,
    this.lines = 1,
  });

  final AddressField field;
  final String label;
  final String? hint;

  /// More than one: a taller box that wraps.
  final int lines;

  @override
  State<AddressTextField> createState() => _AddressTextFieldState();
}

class _AddressTextFieldState extends State<AddressTextField> {
  static const double _tallBox = AppSize.s96;

  late final TextEditingController _controller = TextEditingController(
    text: context.read<AddressEditCubit>().state.draft.valueOf(widget.field),
  );
  final FocusNode _focus = FocusNode();

  /// Whether the field holds text — what the ⊗ follows.
  late final ValueNotifier<bool> _filled = ValueNotifier<bool>(
    _controller.text.isNotEmpty,
  );
  late final Listenable _boxState = Listenable.merge([_focus, _filled]);
  late final TypedTextDirection _direction = TypedTextDirection(
    _controller.text,
  );

  void _changed(String value) {
    _filled.value = value.isNotEmpty;
    _direction.follow(value);
    context.read<AddressEditCubit>().fieldChanged(widget.field, value);
  }

  void _clear() {
    _controller.clear();
    _changed('');
  }

  /// The draft holds [value] for this field: the field shows it, unless it
  /// already does (what was typed is in the draft as typed).
  void _follow(String value) {
    if (value == _controller.text) return;
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _filled.value = value.isNotEmpty;
    _direction.follow(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _filled.dispose();
    _direction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiLine = widget.lines > 1;
    final layout = Directionality.of(context);
    final input = ValueListenableBuilder<bool?>(
      valueListenable: _direction,
      builder: (context, _, _) => TextField(
        controller: _controller,
        textDirection: _direction.directionIn(layout),
        textAlign: TypedTextDirection.startOf(layout),
        focusNode: _focus,
        onChanged: _changed,
        maxLines: widget.lines,
        minLines: widget.lines,
        maxLength: AddressDraft.maxLengthOf(widget.field),
        keyboardType: multiLine ? TextInputType.multiline : TextInputType.text,
        textInputAction: multiLine
            ? TextInputAction.newline
            : TextInputAction.next,
        style: AppTextStyles.itemTitle,
        cursorColor: AppColors.primaryDark,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          hintText: widget.hint,
          hintStyle: AppTextStyles.itemTitle.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ),
    );
    return BlocListener<AddressEditCubit, AddressEditState>(
      listenWhen: (previous, next) =>
          previous.draft.valueOf(widget.field) !=
          next.draft.valueOf(widget.field),
      listener: (_, state) => _follow(state.draft.valueOf(widget.field)),
      child: AddressFieldFrame(
        field: widget.field,
        label: widget.label,
        focus: _focus,
        boxState: _boxState,
        height: multiLine ? _tallBox : AppSize.s56,
        input: input,
        box: (context, child) => Row(
          crossAxisAlignment: multiLine
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s14,
                  vertical: multiLine ? AppSpacing.s12 : 0,
                ),
                child: child,
              ),
            ),
            if (_focus.hasFocus && _filled.value)
              AddressFieldClearButton(
                label: 'addr.field.clear'.tr(
                  namedArgs: {'field': widget.label},
                ),
                onTap: _clear,
              ),
          ],
        ),
      ),
    );
  }
}
