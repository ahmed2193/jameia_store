import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Small tinted chip under the gallery: unit of sale, stock status, product
/// type.
class PdpInfoChip extends StatelessWidget {
  const PdpInfoChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionLarge.copyWith(
          color: foreground,
          fontWeight: AppTextStyles.medium,
        ),
      ),
    );
  }
}
