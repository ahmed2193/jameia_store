import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_step_button.dart';

/// "− 2 +" of the product page's buy bar. The bounds live in the cubit; the
/// buttons only report taps.
class PdpQuantityStepper extends StatelessWidget {
  const PdpQuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // The bar is laid out with the whole screen as its height budget, so
        // nothing in here may size itself from the constraints it is given.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CatalogStepButton(
            icon: Icons.remove_rounded,
            label: 'catalog.decrease_quantity'.tr(),
            onTap: onDecrement,
          ),
          // NOT a Container with an alignment: that is an Align, and an
          // Align with loose constraints grows to the largest size allowed.
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AppSize.s32),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          CatalogStepButton(
            icon: Icons.add_rounded,
            label: 'catalog.increase_quantity'.tr(),
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}
