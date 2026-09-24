import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';
import 'catalog_step_button.dart';

/// The "− qty +" pill a product card shows once the product is in the cart.
/// The minus turns into a bin at quantity 1.
class CatalogPillStepper extends StatelessWidget {
  const CatalogPillStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isLast = qty <= 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CatalogStepButton(
            icon: isLast ? Icons.delete_outline_rounded : Icons.remove_rounded,
            label: isLast
                ? 'catalog.remove'.tr()
                : 'catalog.decrease_quantity'.tr(),
            onTap: onRemove,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: AppSize.s24),
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          CatalogStepButton(
            icon: Icons.add_rounded,
            label: 'catalog.increase_quantity'.tr(),
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
