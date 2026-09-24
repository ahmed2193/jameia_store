import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../responsive/app_size.dart';

/// The floating round button on a product card: "+" for a product one tap can
/// add, a tune icon for a product that needs a choice first (variants).
class CatalogCircleAddButton extends StatelessWidget {
  const CatalogCircleAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  /// Accessibility label.
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: AppSize.s34,
          height: AppSize.s34,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: Icon(
            icon,
            size: AppSize.s20,
            color: AppColors.brandForeground,
          ),
        ),
      ),
    );
  }
}
