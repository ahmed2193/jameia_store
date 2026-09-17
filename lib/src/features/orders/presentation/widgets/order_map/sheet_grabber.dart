import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 14,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
