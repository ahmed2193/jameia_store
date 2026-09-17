import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// Secondary / outline button.
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.divider),
          foregroundColor: AppColors.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r1),
          ),
        ),
        child: Text(label, style: AppTextStyles.headingSmall),
      ),
    );
  }
}
