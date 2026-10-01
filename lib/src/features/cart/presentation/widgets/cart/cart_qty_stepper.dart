import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/rolling_number.dart';
import '../../../../../core/responsive/app_size.dart';
import 'cart_qty_step_button.dart';

/// A cart row's quantity control: a flat white pill with a hairline, 44 dp
/// buttons either side of the count. At 1 the minus becomes a bin (same
/// action: one less removes the line); "+" is off at the stock cap. The
/// count rolls only the digit that changed, and the control keeps a fixed
/// width, so a tap never re-lays out the row.
class CartQtyStepper extends StatelessWidget {
  const CartQtyStepper({
    super.key,
    required this.qty,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
  });

  static const ShapeDecoration _frame = ShapeDecoration(
    color: AppColors.white,
    shape: StadiumBorder(side: BorderSide(color: AppColors.divider)),
  );

  final int qty;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static String _count(num value) => '$value';

  @override
  Widget build(BuildContext context) {
    final last = qty <= 1;
    return DecoratedBox(
      decoration: _frame,
      child: SizedBox(
        height: AppSize.s44,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartQtyStepButton(
              icon: last ? HeroIcons.trash : HeroIcons.minus,
              tooltip: (last ? 'cart.remove' : 'home.decrease_quantity').tr(),
              onTap: onDecrement,
              removes: true,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: AppSize.s24),
              child: Center(
                widthFactor: 1,
                child: RollingNumber(
                  value: qty,
                  format: _count,
                  style: AppTextStyles.label,
                ),
              ),
            ),
            // Its icon never changes, so it needs no cross-fade.
            CartQtyStepButton(
              icon: HeroIcons.plus,
              tooltip: 'home.increase_quantity'.tr(),
              onTap: canIncrement ? onIncrement : null,
              animateIcon: false,
            ),
          ],
        ),
      ),
    );
  }
}
