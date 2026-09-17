import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

/// Jameia order-confirm radio — bundle b3caa4 (selected) / ieba4d (unselected):
/// 16×16dp, 1.9dp ring (#000000 selected / #666666 unselected). A filled centre
/// dot marks the selected state (Jameia shows it via a glyph the CSS atoms omit).
class CheckoutRadio extends StatelessWidget {
  const CheckoutRadio({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.black : AppColors.radioBorder,
          width: 1.9,
        ),
      ),
      child: selected
          ? const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            )
          : null,
    );
  }
}
