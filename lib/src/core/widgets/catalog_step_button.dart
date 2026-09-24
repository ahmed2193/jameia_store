import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';

/// One round − / + / delete button of [CatalogPillStepper].
class CatalogStepButton extends StatelessWidget {
  const CatalogStepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Accessibility label.
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: AppSize.s28,
          height: AppSize.s28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: AppSize.s16,
            color: AppColors.brandForeground,
          ),
        ),
      ),
    );
  }
}
