import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// White block of the product page with an optional bold title.
class PdpSectionCard extends StatelessWidget {
  const PdpSectionCard({
    super.key,
    required this.child,
    this.title = '',
    this.padded = true,
  });

  final Widget child;
  final String title;

  /// `false` for a child that manages its own horizontal padding (a rail).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.s8,
      ),
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s12,
                0,
                AppSpacing.s12,
                AppSpacing.s10,
              ),
              child: Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
          if (padded)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }
}
