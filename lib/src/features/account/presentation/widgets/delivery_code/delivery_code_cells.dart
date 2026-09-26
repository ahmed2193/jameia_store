import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../cubit/delivery_code_state.dart';
import 'delivery_code_cell.dart';

/// The new-code editor: four painted slots over one invisible text field
/// that owns the keyboard, all left-to-right. Accepts Arabic-Indic digits
/// too (the cubit stores them as ASCII).
class DeliveryCodeCells extends StatelessWidget {
  const DeliveryCodeCells({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.draft,
    required this.focused,
    required this.saved,
    required this.onChanged,
  });

  static final RegExp _digit = RegExp('[0-9٠-٩۰-۹]');

  final TextEditingController controller;
  final FocusNode focusNode;
  final String draft;
  final bool focused;
  final bool saved;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < DeliveryCodeState.codeLength; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: DeliveryCodeCell(
                      digit: i < draft.length ? draft[i] : '',
                      active: focused && i == draft.length,
                      saved: saved,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                showCursor: false,
                autocorrect: false,
                enableSuggestions: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(_digit),
                  LengthLimitingTextInputFormatter(
                    DeliveryCodeState.codeLength,
                  ),
                ],
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
