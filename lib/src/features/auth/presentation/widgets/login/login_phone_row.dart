import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'login_phone_box.dart';
import 'login_phone_error.dart';
import 'login_prefix_box.dart';

/// The phone unit: the "Prefix" box and the "Phone number" box side by side
/// — prefix first in either language, as a number is written — with the
/// validation line under both. A new [nudges] value (a tap on the disabled
/// Continue) shakes the unit.
class LoginPhoneRow extends StatelessWidget {
  const LoginPhoneRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorRevealed,
    required this.nudges,
    required this.onSubmitted,
  });

  /// The prefix box takes one share of the row, the number two.
  static const int _prefixFlex = 1;
  static const int _numberFlex = 2;

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> errorRevealed;
  final ValueListenable<int> nudges;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final unit = Row(
      // The order of a written number; the labels keep the page's direction.
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: _prefixFlex,
          child: LoginPrefixBox(onTap: focusNode.requestFocus),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          flex: _numberFlex,
          child: LoginPhoneBox(
            controller: controller,
            focusNode: focusNode,
            errorRevealed: errorRevealed,
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: nudges,
          child: unit,
          builder: (context, count, child) => ShakeX(
            shakeKey: count,
            amplitude: AppSize.s8,
            cycles: 3,
            child: child!,
          ),
        ),
        LoginPhoneError(revealed: errorRevealed),
      ],
    );
  }
}
