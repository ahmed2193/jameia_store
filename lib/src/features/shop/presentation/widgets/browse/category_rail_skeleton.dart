import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';
import 'category_rail.dart';

/// The bones of the sub-category rail while the store's tree loads: a row
/// of round pictures with a name under each, at the rail's full height.
class CategoryRailSkeleton extends StatelessWidget {
  const CategoryRailSkeleton({super.key});

  static const int _items = 6;
  static const double _item = AppSize.s78;
  static const double _picture = AppSize.s54;
  static const double _label = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CategoryRail.height,
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          maxWidth: double.infinity,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _items; i++)
                  const SizedBox(
                    width: _item,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBone(
                          width: _picture,
                          height: _picture,
                          radius: AppRadius.pill,
                        ),
                        SizedBox(height: AppSpacing.s8),
                        SkeletonBone(width: _label, height: AppSize.s10),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
