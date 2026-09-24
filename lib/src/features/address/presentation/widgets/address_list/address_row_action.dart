import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';

/// Compact 32dp icon button (RE §5 tap target) for a row action.
class AddressRowAction extends StatelessWidget {
  const AddressRowAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.s32,
      height: AppSize.s32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        icon: Icon(icon, size: AppSize.s18, color: AppColors.secondaryText),
        onPressed: onPressed,
      ),
    );
  }
}
