import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../cubit/delivery_code_state.dart';
import 'delivery_code_digit_box.dart';

/// The saved code as four big tiles, always left-to-right (a code reads the
/// same in Arabic). A screen reader hears the digits one by one. The first
/// code to show (the load) appears at once; only a real change ([animate])
/// flips the digits that differ.
class DeliveryCodeDigits extends StatelessWidget {
  const DeliveryCodeDigits({
    super.key,
    required this.code,
    this.animate = false,
  });

  final String code;

  /// Whether a new [code] is a real change (a save), which flips.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: code.split('').join(' '),
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (var i = 0; i < DeliveryCodeState.codeLength; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: DeliveryCodeDigitBox(
                    digit: i < code.length ? code[i] : '',
                    animate: animate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
