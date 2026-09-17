import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';

// ── White card shell shared by all detail sections ────────────────────────────
//
// Real Jameia metrics (bundle.css.json, ee3706 / a15c8b):
//   margin:  6dp top / 9dp horizontal / 9dp bottom
//   border-radius: 16dp (AppRadius.r3)
//   padding: 16dp horizontal, 16dp vertical (adapted from 14dp 20dp for consistency)
//   bg: #ffffff

class TrackingCard extends StatelessWidget {
  const TrackingCard({super.key, required this.child, this.padding});
  final Widget child;
  // Allows callers to override inner padding (e.g. help rows need 0 padding to
  // let individual rows control their own horizontal pad).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.only(
        start: AppSpacing.pageMargin,
        end: AppSpacing.pageMargin,
        top: AppSpacing.s6,
        bottom: AppSpacing.pageMargin,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3), // 16dp
      ),
      padding:
          padding ??
          const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s16,
          ),
      child: child,
    );
  }
}
