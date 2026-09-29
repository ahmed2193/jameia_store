import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';

/// The bones of one [BrandTile] while the brands load: the white card, the
/// round logo, the name and one line of description, in the tile's own
/// margins — so the real rows land where the bones stood.
class BrandTileSkeleton extends StatelessWidget {
  const BrandTileSkeleton({super.key});

  static const double _logo = AppSize.s56;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        0,
        AppSpacing.s12,
        AppSpacing.s8,
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Row(
        children: [
          SkeletonBone(width: _logo, height: _logo, radius: AppRadius.pill),
          SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: AppSize.s140, height: AppSize.s14),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(width: AppSize.s220, height: AppSize.s12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
