import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// One flat block of the product page's sheet: edge to edge, 16 dp gutters,
/// an optional bold ink title. It paints no background of its own (the
/// white is the sheet's, so the first block keeps the sheet's rounded
/// corners). Blocks are set apart by [PdpSectionDivider] hairlines, never
/// floated as cards.
class PdpSection extends StatelessWidget {
  const PdpSection({
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
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s16,
                  0,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            if (padded)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s16,
                ),
                child: child,
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}
