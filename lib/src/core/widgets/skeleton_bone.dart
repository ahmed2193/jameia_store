import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

/// A single grey bone block — building unit for the skeleton layouts.
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.r6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
