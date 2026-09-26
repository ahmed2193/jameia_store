import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/skeleton_bone.dart';
import '../../../../core/widgets/skeletonized.dart';

/// Bone rows shaped like [SearchSuggestionTile]s while the first product
/// request for the typed text runs (a still fill under reduced motion).
class SearchSuggestionSkeleton extends StatelessWidget {
  const SearchSuggestionSkeleton({super.key});

  static const int _rows = 3;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Skeletonized(
        loading: true,
        child: Column(
          children: [
            for (var i = 0; i < _rows; i++)
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.s8,
                ),
                child: Row(
                  children: [
                    SkeletonBone(
                      width: AppSize.s48,
                      height: AppSize.s48,
                      radius: AppRadius.card,
                    ),
                    SizedBox(width: AppSpacing.s12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(width: AppSize.s160, height: AppSize.s14),
                        SizedBox(height: AppSpacing.s8),
                        SkeletonBone(width: AppSize.s80, height: AppSize.s12),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
