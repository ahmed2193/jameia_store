import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/skeleton_bone.dart';

/// The bones of one [RecipeListTile] while the recipes load: the white card,
/// the square photo, two title lines, a teaser line and the tag row, in the
/// tile's own margins — so the real cards land where the bones stood.
class RecipeTileSkeleton extends StatelessWidget {
  const RecipeTileSkeleton({super.key});

  static const double _image = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        0,
        AppSpacing.s12,
        AppSpacing.s8,
      ),
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBone(width: _image, height: _image, radius: AppSize.r10),
          SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: AppSize.s180, height: AppSize.s14),
                SizedBox(height: AppSpacing.s6),
                SkeletonBone(width: AppSize.s120, height: AppSize.s14),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(width: AppSize.s220, height: AppSize.s12),
                SizedBox(height: AppSpacing.s10),
                Row(
                  children: [
                    SkeletonBone(
                      width: AppSize.s56,
                      height: AppSize.s18,
                      radius: AppRadius.pill,
                    ),
                    SizedBox(width: AppSpacing.s4),
                    SkeletonBone(width: AppSize.s90, height: AppSize.s12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
