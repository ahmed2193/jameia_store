import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/blocked_tap_shake.dart';
import '../../../../core/motion/rolling_number.dart';
import 'pdp_step_button.dart';

/// "−  2  +" inside the buy bar's filled pill once the selection is in the
/// cart: the count of that cart line rolls as it changes. The bounds come
/// from the cart and the stock; the buttons only report taps. A "+" at the
/// stock limit says no when tapped: it shakes with a warning haptic
/// ([BlockedTapShake], §9.4 #3).
class PdpCtaStepper extends StatelessWidget {
  const PdpCtaStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.canIncrement = true,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PdpStepButton(
          icon: Icons.remove_rounded,
          label: 'catalog.decrease_quantity'.tr(),
          onTap: onDecrement,
          removes: true,
          color: AppColors.brandForeground,
          disabledColor: AppColors.brandLightBg,
        ),
        Expanded(
          child: Center(
            child: RollingNumber(
              value: quantity,
              format: (value) => '${value.toInt()}',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.brandForeground,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),
        BlockedTapShake(
          blocked: !canIncrement,
          child: PdpStepButton(
            icon: Icons.add_rounded,
            label: 'catalog.increase_quantity'.tr(),
            onTap: onIncrement,
            active: canIncrement,
            color: AppColors.brandForeground,
            disabledColor: AppColors.brandLightBg,
          ),
        ),
      ],
    );
  }
}
