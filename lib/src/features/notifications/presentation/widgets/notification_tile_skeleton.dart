import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/skeleton_bone.dart';

/// The bones of one [NotificationTile] while the inbox loads: the round kind
/// glyph, a title, two lines of body and the time, in the row's own padding.
class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  static const double _glyph = AppSize.s40;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBone(width: _glyph, height: _glyph, radius: AppRadius.pill),
          SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: AppSize.s180, height: AppSize.s14),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(width: AppSize.s240, height: AppSize.s12),
                SizedBox(height: AppSpacing.s4),
                SkeletonBone(width: AppSize.s150, height: AppSize.s12),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(width: AppSize.s60, height: AppSize.s10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
