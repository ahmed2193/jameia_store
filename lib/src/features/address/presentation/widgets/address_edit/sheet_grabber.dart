import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';

/// Small grabber handle shown at the top of either address-edit sheet.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
